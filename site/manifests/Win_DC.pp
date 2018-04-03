class site::Win_DC {
  if $osfamily == 'windows' {
    include windows_ad
  }
}
