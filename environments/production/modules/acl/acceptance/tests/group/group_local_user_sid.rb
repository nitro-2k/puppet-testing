test_name 'Windows ACL Module - Change Group to Local User SID'

confine(:to, :platform => 'windows')

#Globals
os_check_command = "cmd /c ver"
os_check_regex = /Version 5/

user_type = 'local_user_sid'
file_content = 'Hot eyes in your sand!'

parent_name = 'temp'
target_name = "group_#{user_type}.txt"

target_parent = "c:/#{parent_name}"
target = "#{target_parent}/#{target_name}"
user_id = 'bob'
group_id = 'jerry'

get_group_sid_command = <<-GETSID
cmd /c "wmic useraccount where name='#{group_id}' get sid"
GETSID

sid_regex = /^(S-.+)$/

verify_content_command = "cat /cygdrive/c/#{parent_name}/#{target_name}"
file_content_regex = /\A#{file_content}\z/

verify_group_command = "icacls #{target}"
group_regex = /.*\\jerry:\(M\)/

#Capture the SID for later use.
sid = ''

#Manifests
setup_manifest = <<-MANIFEST
file { "#{target_parent}":
  ensure => directory
}

file { "#{target}":
  ensure  => file,
  content => '#{file_content}',
  require => File['#{target_parent}']
}

user { "#{user_id}":
  ensure     => present,
  groups     => 'Users',
  managehome => true,
  password   => "L0v3Pupp3t!"
}

user { "#{group_id}":
  ensure     => present,
  groups     => 'Users',
  managehome => true,
  password   => "L0v3Pupp3t!"
}
MANIFEST

#Tests
agents.each do |agent|
  #Determine if running on Windows 2003.
  #Skip if 2003 because the wmic command doesn't work right on Windows 2003.
  step "Determine OS Type"
  on(agent, os_check_command) do |result|
    if os_check_regex =~ result.stdout
      skip_test("This test cannot run on a Windows 2003 system!")
    end
  end

  step "Execute Setup Manifest"
  on(agent, puppet('apply', '--debug'), :stdin => setup_manifest) do |result|
    assert_no_match(/Error:/, result.stderr, 'Unexpected error was detected!')
  end

  step "Get SID of User Account"
  on(agent, get_group_sid_command) do |result|
    sid = sid_regex.match(result.stdout)[1]
  end

  #ACL manifest
  acl_manifest = <<-MANIFEST
  acl { "#{target}":
    purge           => 'true',
    permissions     => [
      { identity    => 'CREATOR GROUP',
        rights      => ['modify']
      },
      { identity    => '#{user_id}',
        rights      => ['read']
      },
      { identity    => 'Administrators',
        rights      => ['full'],
        affects     => 'all',
        child_types => 'all'
      }
    ],
    group           => '#{sid}',
    inherit_parent_permissions => 'false'
  }
  MANIFEST

  step "Execute ACL Manifest"
  on(agent, puppet('apply', '--debug'), :stdin => acl_manifest) do |result|
    assert_no_match(/Error:/, result.stderr, 'Unexpected error was detected!')
  end

  step "Verify that ACL Rights are Correct"
  on(agent, verify_group_command) do |result|
    assert_match(group_regex, result.stdout, 'Expected ACL was not present!')
  end

  step "Verify File Data Integrity"
  on(agent, verify_content_command) do |result|
    assert_match(file_content_regex, result.stdout, 'File content is invalid!')
  end
end
