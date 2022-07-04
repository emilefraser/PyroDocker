from .. import bp
from flask import request, render_template, flash, redirect, url_for
from flask_login import login_required
from app.lib.base.provider import Provider
from app.lib.base.decorators import admin_required


@bp.route('/dns', methods=['GET'])
@login_required
@admin_required
def dns():
    return render_template('config/system/dns.html')


@bp.route('/dns/save', methods=['POST'])
@login_required
@admin_required
def dns_save():
    provider = Provider()
    settings = provider.settings()
    dns = provider.dns_manager()

    # DNS Base Domain
    dns_base_domain = request.form['dns_base_domain'].strip()

    # DNS Daemon
    dns_daemon_bind_ip = request.form['dns_daemon_bind_ip'].strip()
    dns_daemon_bind_port = request.form['dns_daemon_bind_port'].strip()
    dns_daemon_bind_port = int(dns_daemon_bind_port) if dns_daemon_bind_port.isdigit() else 0
    dns_daemon_start_everyone = True if int(request.form.get('dns_daemon_start_everyone', 0)) == 1 else False
    dns_cache_enabled = True if int(request.form.get('dns_cache_enabled', 0)) == 1 else False
    dns_cache_max_items = request.form['dns_cache_max_items'].strip()
    dns_cache_max_items = int(dns_cache_max_items) if dns_cache_max_items.isdigit() else 0
    dns_delete_logs_after_days = request.form['dns_delete_logs_after_days'].strip()
    dns_delete_logs_after_days = int(dns_delete_logs_after_days) if dns_delete_logs_after_days.isdigit() else 0

    # DNS Forwarding
    forward_dns_address = request.form['forward_dns_address'].strip()
    forward_dns_enabled = True if int(request.form.get('forward_dns_enabled', 0)) == 1 else False

    # DNS CSV Logging
    csv_logging_file = request.form['csv_logging_file'].strip()
    csv_logging_enabled = True if int(request.form.get('csv_logging_enabled', 0)) == 1 else False

    # DNS Daemon Validation
    if not dns.is_valid_ip_address(dns_daemon_bind_ip):
        flash('Invalid IP Address', 'error')
        return redirect(url_for('config.dns'))
    elif dns_daemon_bind_port <= 0 or dns_daemon_bind_port > 65535:
        flash('Invalid Port', 'error')
        return redirect(url_for('config.dns'))
    elif dns_daemon_bind_port < 1024:
        flash('Please enter a port between 1024 and 65535. Port numbers below 1024 require root access.', 'error')
        return redirect(url_for('config.dns'))

    if dns_cache_max_items < 0:
        dns_cache_max_items = 0
    if dns_delete_logs_after_days < 0:
        dns_delete_logs_after_days = 0;

    # DNS Forwarding Validation
    forwarders = []
    for item in forward_dns_address.split(','):
        item = item.strip()
        if len(item) > 0:
            if dns.is_valid_forwarder(item):
                forwarders.append(item)

    # DNS CSV Logging Validation
    if csv_logging_enabled:
        if len(csv_logging_file) == 0:
            flash('Please enter a CSV output location', 'error')
            return redirect(url_for('config.dns'))
        elif not dns.is_file_writable(csv_logging_file):
            flash('CSV output location is not writable', 'error')
            return redirect(url_for('config.dns'))

    # Save Base Domain
    settings.save('dns_base_domain', dns_base_domain)

    # Save Daemon
    settings.save('dns_daemon_bind_ip', dns_daemon_bind_ip)
    settings.save('dns_daemon_bind_port', dns_daemon_bind_port)
    settings.save('dns_daemon_start_everyone', dns_daemon_start_everyone)
    settings.save('dns_cache_enabled', dns_cache_enabled)
    settings.save('dns_cache_max_items', dns_cache_max_items)
    settings.save('dns_delete_logs_after_days', dns_delete_logs_after_days)

    # Save Forwarding
    settings.save('forward_dns_address', forwarders)
    settings.save('forward_dns_enabled', forward_dns_enabled)

    # Save Logging
    settings.save('csv_logging_file', csv_logging_file)
    settings.save('csv_logging_enabled', csv_logging_enabled)

    flash('Settings saved - Please restart the DNS Daemon.', 'success')
    return redirect(url_for('config.dns'))
