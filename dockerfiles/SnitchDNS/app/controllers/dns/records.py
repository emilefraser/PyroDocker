from . import bp
from flask_login import current_user, login_required
from flask import render_template, redirect, url_for, flash, request
from app.lib.base.provider import Provider


@bp.route('/<int:dns_zone_id>/record/<int:dns_record_id>/edit', methods=['GET'])
@login_required
def record_edit(dns_zone_id, dns_record_id):
    provider = Provider()
    zones = provider.dns_zones()
    records = provider.dns_records()

    if not zones.can_access(dns_zone_id, current_user.id):
        flash('Access Denied', 'error')
        return redirect(url_for('home.index'))
    elif dns_record_id > 0:
        if not records.can_access(dns_zone_id, dns_record_id):
            flash('Access Denied', 'error')
            return redirect(url_for('home.index'))

    zone = zones.get(dns_zone_id)
    if not zone:
        flash('Zone not found', 'error')
        return redirect(url_for('home.index'))

    record = records.get(dns_record_id, zone.id)
    if dns_record_id > 0:
        if not record:
            flash('Could not load record', 'error')
            return redirect(url_for('home.index'))

    dns_types = records.get_types()
    dns_classes = records.get_classes()

    return render_template(
        'dns/zones/view.html',
        dns_record_id=dns_record_id,
        dns_types=dns_types,
        dns_classes=dns_classes,
        zone=zone,
        record=record,
        section='records_edit',
        tab='records'
    )


@bp.route('/<int:dns_zone_id>/record/<int:dns_record_id>/edit/save', methods=['POST'])
@login_required
def record_edit_save(dns_zone_id, dns_record_id):
    provider = Provider()
    zones = provider.dns_zones()
    records = provider.dns_records()

    if not zones.can_access(dns_zone_id, current_user.id):
        flash('Access Denied', 'error')
        return redirect(url_for('home.index'))
    elif dns_record_id > 0:
        if not records.can_access(dns_zone_id, dns_record_id):
            flash('Access Denied', 'error')
            return redirect(url_for('home.index'))

    zone = zones.get(dns_zone_id)
    dns_types = records.get_types()
    dns_classes = records.get_classes()

    ttl = int(request.form['ttl'].strip())
    cls = request.form['class'].strip()
    type = request.form['type'].strip()
    active = True if int(request.form.get('active', 0)) == 1 else False
    has_conditional_responses = True if int(request.form.get('has_conditional_responses', 0)) == 1 else False

    if ttl < 0:
        flash('Invalid TTL value', 'error')
        return redirect(url_for('dns.record_edit', dns_zone_id=dns_zone_id, dns_record_id=dns_record_id))
    elif cls not in dns_classes:
        flash('Invalid class value', 'error')
        return redirect(url_for('dns.record_edit', dns_zone_id=dns_zone_id, dns_record_id=dns_record_id))
    elif type not in dns_types:
        flash('Invalid type value', 'error')
        return redirect(url_for('dns.record_edit', dns_zone_id=dns_zone_id, dns_record_id=dns_record_id))

    # Depending on the type, get the right properties.
    data = gather_record_data(type)
    if data is False:
        # Flash errors should already be set in gather_record_data()
        return redirect(url_for('dns.record_edit', dns_zone_id=dns_zone_id, dns_record_id=dns_record_id))

    if dns_record_id > 0:
        record = records.get(dns_record_id, zone.id)
        if not record:
            flash('Could not get record', 'error')
            return redirect(url_for('dns.record_edit', dns_zone_id=dns_zone_id, dns_record_id=dns_record_id))
    else:
        record = records.create()

    record = records.save(record, zone.id, ttl, cls, type, data, active)
    if not record:
        flash('Could not save record', 'error')
        return redirect(url_for('dns.record_edit', dns_zone_id=dns_zone_id, dns_record_id=dns_record_id))

    records.save_conditions(record, enabled=has_conditional_responses)

    flash('Record saved', 'success')
    return redirect(url_for('dns.zone_view', dns_zone_id=dns_zone_id))


@bp.route('/<int:dns_zone_id>/record/<int:dns_record_id>/delete', methods=['POST'])
@login_required
def record_delete(dns_zone_id, dns_record_id):
    provider = Provider()
    zones = provider.dns_zones()
    records = provider.dns_records()

    if not zones.can_access(dns_zone_id, current_user.id):
        flash('Access Denied', 'error')
        return redirect(url_for('home.index'))

    zone = zones.get(dns_zone_id)
    record = records.get(dns_record_id, dns_zone_id=zone.id)
    if not zone:
        flash('Zone not found', 'error')
        return redirect(url_for('home.index'))
    elif not record:
        flash('Record not found', 'error')
        return redirect(url_for('home.index'))

    records.delete(record)
    flash('Record deleted', 'success')
    return redirect(url_for('dns.zone_view', dns_zone_id=dns_zone_id))


def gather_record_data(record_type):
    provider = Provider()
    records = provider.dns_records()

    data = {}
    properties = records.get_record_type_properties(record_type)

    for property, type in properties.items():
        value = request.form[property].strip()
        if type == 'int':
            if not value.isdigit():
                flash('Invalid {0} value'.format(property), 'error')
                return False
            value = int(value)

        if (type == 'str') and (len(value) == 0):
            flash('Invalid {0} value'.format(property), 'error')
            return False
        elif (type == 'int') and (value < 0):
            flash('Invalid {0} value'.format(property), 'error')
            return False

        if property in ['name2', 'preference2', 'algorithm2']:
            # There are multiple form fields like 'name', 'name2', 'name3',
            # it's easier to clean them up this way than use duplicate names.
            property = property.rstrip('2')
        data[property] = value

    return data


@bp.route('/<int:dns_zone_id>/record/<int:dns_record_id>/conditions/edit', methods=['GET'])
@login_required
def record_conditions_edit(dns_zone_id, dns_record_id):
    provider = Provider()
    zones = provider.dns_zones()
    records = provider.dns_records()

    if not zones.can_access(dns_zone_id, current_user.id):
        flash('Access Denied', 'error')
        return redirect(url_for('home.index'))
    elif dns_record_id > 0:
        if not records.can_access(dns_zone_id, dns_record_id):
            flash('Access Denied', 'error')
            return redirect(url_for('home.index'))
    elif dns_record_id == 0:
        flash('Please create and save your record first', 'error')
        return redirect(url_for('home.index'))

    zone = zones.get(dns_zone_id)
    if not zone:
        flash('Zone not found', 'error')
        return redirect(url_for('home.index'))

    record = records.get(dns_record_id, zone.id)
    if dns_record_id > 0:
        if not record:
            flash('Could not load record', 'error')
            return redirect(url_for('home.index'))

    dns_types = records.get_types()
    dns_classes = records.get_classes()

    return render_template(
        'dns/zones/view.html',
        dns_record_id=dns_record_id,
        dns_types=dns_types,
        dns_classes=dns_classes,
        zone=zone,
        record=record,
        section='conditions_edit',
        tab='records'
    )


@bp.route('/<int:dns_zone_id>/record/<int:dns_record_id>/conditions/edit/save', methods=['POST'])
@login_required
def record_conditions_edit_save(dns_zone_id, dns_record_id):
    provider = Provider()
    zones = provider.dns_zones()
    records = provider.dns_records()

    if not zones.can_access(dns_zone_id, current_user.id):
        flash('Access Denied', 'error')
        return redirect(url_for('home.index'))
    elif dns_record_id > 0:
        if not records.can_access(dns_zone_id, dns_record_id):
            flash('Access Denied', 'error')
            return redirect(url_for('home.index'))
    elif dns_record_id == 0:
        flash('Please create and save your record first', 'error')
        return redirect(url_for('home.index'))

    record = records.get(dns_record_id, dns_zone_id)
    if not record:
        flash('There was an error retrieving the DNS Record', 'error')
        return redirect(url_for('dns.record_conditions_edit', dns_zone_id=dns_zone_id, dns_record_id=dns_record_id))

    conditional_limit = int(request.form['conditional_limit'].strip())
    conditional_reset = True if int(request.form.get('conditional_reset', 0)) == 1 else False
    conditional_count = request.form['conditional_count'].strip()
    conditional_count = 0 if len(conditional_count) == 0 else int(conditional_count)

    if conditional_limit <= 0:
        flash('Invalid DNS query limit', 'error')
        return redirect(url_for('dns.record_conditions_edit', dns_zone_id=dns_zone_id, dns_record_id=dns_record_id))
    elif conditional_count < 0:
        flash('Invalid DNS query current count', 'error')
        return redirect(url_for('dns.record_conditions_edit', dns_zone_id=dns_zone_id, dns_record_id=dns_record_id))

    # Depending on the type, get the right properties.
    data = gather_record_data(record.type)
    if data is False:
        # Flash errors should already be set in gather_record_data()
        return redirect(url_for('dns.record_edit', dns_zone_id=dns_zone_id, dns_record_id=dns_record_id))

    record = records.save_conditions(record, data=data, count=conditional_count, limit=conditional_limit, reset=conditional_reset)
    if not record:
        flash('Could not save record', 'error')
        return redirect(url_for('dns.record_edit', dns_zone_id=dns_zone_id, dns_record_id=dns_record_id))

    flash('Record saved', 'success')
    return redirect(url_for('dns.zone_view', dns_zone_id=dns_zone_id))
