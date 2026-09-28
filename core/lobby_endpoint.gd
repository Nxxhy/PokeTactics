extends RefCounted

static func allowed(value: String) -> bool:
 if value.begins_with("https://"): return true
 if not value.begins_with("http://"): return false
 var authority = value.trim_prefix("http://").trim_suffix("/")
 var parts = authority.split(":")
 if parts.size() != 2 or not parts[1].is_valid_int(): return false
 if int(parts[1]) < 1 or int(parts[1]) > 65535: return false
 var ip = parts[0]
 if not ip.is_valid_ip_address(): return false
 var octets = ip.split(".")
 if octets.size() != 4: return false
 var first = int(octets[0])
 var second = int(octets[1])
 return first == 127 or first == 10 or (first == 172 and second >= 16 and second <= 31) or (first == 192 and second == 168)
