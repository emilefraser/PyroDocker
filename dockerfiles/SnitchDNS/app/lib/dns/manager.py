import ipaddress
import os
import re


class DNSManager:
    def __init__(self, zones, records, logs, settings):
        self.zone_manager = zones
        self.record_manager = records
        self.logs_manager = logs
        self.settings = settings

    @property
    def forwarders(self):
        return self.settings.get('forward_dns_address', [], type=list)

    @property
    def is_forwarding_enabled(self):
        return self.settings.get('forward_dns_enabled', False, type=bool)

    def is_valid_ip_address(self, ip):
        try:
            obj = ipaddress.ip_address(ip)
        except ValueError:
            return False

        return True

    def is_valid_forwarder(self, value):
        item = value.split(':')

        if len(item) == 1:
            # There's only an IP.
            return self.is_valid_ip_address(value)
        elif len(item) == 2:
            # Both IP:Port
            if not self.is_valid_ip_address(item[0]):
                return False
            try:
                port = int(item[1])
                return 0 < port < 65535
            except ValueError:
                return False

        return False

    def find_zone(self, domain, original_domain, validate_catch_all=True):
        zone = self.zone_manager.find(domain)
        if zone is False:
            return False
        elif not zone.active:
            return False

        # Check if it's marked as an 'exact match' (not 'catch all').
        # If it is, in order for it to be used here the query.qname (the DNS request that came in) must match the
        # 'full domain' of this result. Because the returned value could be 'hi.bye.contextis.com' and set as
        # 'exact match' but the original query could be for 'greeting.hi.bye.contextis.com'
        # The 'validate_exact_match' was added to add the option to skip this check to make CNAME responses easier.
        if not zone.catch_all and validate_catch_all:
            if zone.domain != original_domain:
                return False

        return zone

    def get_zone(self, dns_zone_id):
        return self.zone_manager.get(dns_zone_id)

    def find_zone_regex(self, domain):
        zones = self.zone_manager.load_regex_domains()
        for zone in zones:
            if re.search(zone.domain, domain):
                if not zone.active:
                    break
                return zone

        return False

    def find_all_records(self, zone, cls, type, active=None):
        records = self.record_manager.find(zone.id, cls, type, active=active)
        if records is False:
            return []
        return records if len(records) > 0 else []

    def is_file_writable(self, path):
        return os.access(path, os.W_OK) if os.path.isfile(path) else os.access(os.path.dirname(path), os.W_OK)
