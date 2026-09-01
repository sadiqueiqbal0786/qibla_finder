// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $PreferencesTable extends Preferences
    with TableInfo<$PreferencesTable, Preference> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PreferencesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'preferences';
  @override
  VerificationContext validateIntegrity(
    Insertable<Preference> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  Preference map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Preference(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $PreferencesTable createAlias(String alias) {
    return $PreferencesTable(attachedDatabase, alias);
  }
}

class Preference extends DataClass implements Insertable<Preference> {
  final String key;
  final String value;
  const Preference({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  PreferencesCompanion toCompanion(bool nullToAbsent) {
    return PreferencesCompanion(key: Value(key), value: Value(value));
  }

  factory Preference.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Preference(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  Preference copyWith({String? key, String? value}) =>
      Preference(key: key ?? this.key, value: value ?? this.value);
  Preference copyWithCompanion(PreferencesCompanion data) {
    return Preference(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Preference(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Preference &&
          other.key == this.key &&
          other.value == this.value);
}

class PreferencesCompanion extends UpdateCompanion<Preference> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const PreferencesCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PreferencesCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<Preference> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PreferencesCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return PreferencesCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PreferencesCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SavedLocationsTable extends SavedLocations
    with TableInfo<$SavedLocationsTable, SavedLocation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SavedLocationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 120,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _latitudeMeta = const VerificationMeta(
    'latitude',
  );
  @override
  late final GeneratedColumn<double> latitude = GeneratedColumn<double>(
    'latitude',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _longitudeMeta = const VerificationMeta(
    'longitude',
  );
  @override
  late final GeneratedColumn<double> longitude = GeneratedColumn<double>(
    'longitude',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isoCountryCodeMeta = const VerificationMeta(
    'isoCountryCode',
  );
  @override
  late final GeneratedColumn<String> isoCountryCode = GeneratedColumn<String>(
    'iso_country_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _utcOffsetHoursMeta = const VerificationMeta(
    'utcOffsetHours',
  );
  @override
  late final GeneratedColumn<double> utcOffsetHours = GeneratedColumn<double>(
    'utc_offset_hours',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isCurrentMeta = const VerificationMeta(
    'isCurrent',
  );
  @override
  late final GeneratedColumn<bool> isCurrent = GeneratedColumn<bool>(
    'is_current',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_current" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _savedAtMeta = const VerificationMeta(
    'savedAt',
  );
  @override
  late final GeneratedColumn<DateTime> savedAt = GeneratedColumn<DateTime>(
    'saved_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    label,
    latitude,
    longitude,
    isoCountryCode,
    utcOffsetHours,
    isCurrent,
    savedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'saved_locations';
  @override
  VerificationContext validateIntegrity(
    Insertable<SavedLocation> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    } else if (isInserting) {
      context.missing(_labelMeta);
    }
    if (data.containsKey('latitude')) {
      context.handle(
        _latitudeMeta,
        latitude.isAcceptableOrUnknown(data['latitude']!, _latitudeMeta),
      );
    } else if (isInserting) {
      context.missing(_latitudeMeta);
    }
    if (data.containsKey('longitude')) {
      context.handle(
        _longitudeMeta,
        longitude.isAcceptableOrUnknown(data['longitude']!, _longitudeMeta),
      );
    } else if (isInserting) {
      context.missing(_longitudeMeta);
    }
    if (data.containsKey('iso_country_code')) {
      context.handle(
        _isoCountryCodeMeta,
        isoCountryCode.isAcceptableOrUnknown(
          data['iso_country_code']!,
          _isoCountryCodeMeta,
        ),
      );
    }
    if (data.containsKey('utc_offset_hours')) {
      context.handle(
        _utcOffsetHoursMeta,
        utcOffsetHours.isAcceptableOrUnknown(
          data['utc_offset_hours']!,
          _utcOffsetHoursMeta,
        ),
      );
    }
    if (data.containsKey('is_current')) {
      context.handle(
        _isCurrentMeta,
        isCurrent.isAcceptableOrUnknown(data['is_current']!, _isCurrentMeta),
      );
    }
    if (data.containsKey('saved_at')) {
      context.handle(
        _savedAtMeta,
        savedAt.isAcceptableOrUnknown(data['saved_at']!, _savedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SavedLocation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SavedLocation(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      )!,
      latitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}latitude'],
      )!,
      longitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}longitude'],
      )!,
      isoCountryCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}iso_country_code'],
      ),
      utcOffsetHours: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}utc_offset_hours'],
      ),
      isCurrent: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_current'],
      )!,
      savedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}saved_at'],
      )!,
    );
  }

  @override
  $SavedLocationsTable createAlias(String alias) {
    return $SavedLocationsTable(attachedDatabase, alias);
  }
}

class SavedLocation extends DataClass implements Insertable<SavedLocation> {
  final int id;
  final String label;
  final double latitude;
  final double longitude;
  final String? isoCountryCode;

  /// UTC offset in hours for this place, so prayer times can be rendered in
  /// local-to-the-place time rather than device time.
  final double? utcOffsetHours;

  /// True for the row tracking the device's current position.
  final bool isCurrent;
  final DateTime savedAt;
  const SavedLocation({
    required this.id,
    required this.label,
    required this.latitude,
    required this.longitude,
    this.isoCountryCode,
    this.utcOffsetHours,
    required this.isCurrent,
    required this.savedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['label'] = Variable<String>(label);
    map['latitude'] = Variable<double>(latitude);
    map['longitude'] = Variable<double>(longitude);
    if (!nullToAbsent || isoCountryCode != null) {
      map['iso_country_code'] = Variable<String>(isoCountryCode);
    }
    if (!nullToAbsent || utcOffsetHours != null) {
      map['utc_offset_hours'] = Variable<double>(utcOffsetHours);
    }
    map['is_current'] = Variable<bool>(isCurrent);
    map['saved_at'] = Variable<DateTime>(savedAt);
    return map;
  }

  SavedLocationsCompanion toCompanion(bool nullToAbsent) {
    return SavedLocationsCompanion(
      id: Value(id),
      label: Value(label),
      latitude: Value(latitude),
      longitude: Value(longitude),
      isoCountryCode: isoCountryCode == null && nullToAbsent
          ? const Value.absent()
          : Value(isoCountryCode),
      utcOffsetHours: utcOffsetHours == null && nullToAbsent
          ? const Value.absent()
          : Value(utcOffsetHours),
      isCurrent: Value(isCurrent),
      savedAt: Value(savedAt),
    );
  }

  factory SavedLocation.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SavedLocation(
      id: serializer.fromJson<int>(json['id']),
      label: serializer.fromJson<String>(json['label']),
      latitude: serializer.fromJson<double>(json['latitude']),
      longitude: serializer.fromJson<double>(json['longitude']),
      isoCountryCode: serializer.fromJson<String?>(json['isoCountryCode']),
      utcOffsetHours: serializer.fromJson<double?>(json['utcOffsetHours']),
      isCurrent: serializer.fromJson<bool>(json['isCurrent']),
      savedAt: serializer.fromJson<DateTime>(json['savedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'label': serializer.toJson<String>(label),
      'latitude': serializer.toJson<double>(latitude),
      'longitude': serializer.toJson<double>(longitude),
      'isoCountryCode': serializer.toJson<String?>(isoCountryCode),
      'utcOffsetHours': serializer.toJson<double?>(utcOffsetHours),
      'isCurrent': serializer.toJson<bool>(isCurrent),
      'savedAt': serializer.toJson<DateTime>(savedAt),
    };
  }

  SavedLocation copyWith({
    int? id,
    String? label,
    double? latitude,
    double? longitude,
    Value<String?> isoCountryCode = const Value.absent(),
    Value<double?> utcOffsetHours = const Value.absent(),
    bool? isCurrent,
    DateTime? savedAt,
  }) => SavedLocation(
    id: id ?? this.id,
    label: label ?? this.label,
    latitude: latitude ?? this.latitude,
    longitude: longitude ?? this.longitude,
    isoCountryCode: isoCountryCode.present
        ? isoCountryCode.value
        : this.isoCountryCode,
    utcOffsetHours: utcOffsetHours.present
        ? utcOffsetHours.value
        : this.utcOffsetHours,
    isCurrent: isCurrent ?? this.isCurrent,
    savedAt: savedAt ?? this.savedAt,
  );
  SavedLocation copyWithCompanion(SavedLocationsCompanion data) {
    return SavedLocation(
      id: data.id.present ? data.id.value : this.id,
      label: data.label.present ? data.label.value : this.label,
      latitude: data.latitude.present ? data.latitude.value : this.latitude,
      longitude: data.longitude.present ? data.longitude.value : this.longitude,
      isoCountryCode: data.isoCountryCode.present
          ? data.isoCountryCode.value
          : this.isoCountryCode,
      utcOffsetHours: data.utcOffsetHours.present
          ? data.utcOffsetHours.value
          : this.utcOffsetHours,
      isCurrent: data.isCurrent.present ? data.isCurrent.value : this.isCurrent,
      savedAt: data.savedAt.present ? data.savedAt.value : this.savedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SavedLocation(')
          ..write('id: $id, ')
          ..write('label: $label, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('isoCountryCode: $isoCountryCode, ')
          ..write('utcOffsetHours: $utcOffsetHours, ')
          ..write('isCurrent: $isCurrent, ')
          ..write('savedAt: $savedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    label,
    latitude,
    longitude,
    isoCountryCode,
    utcOffsetHours,
    isCurrent,
    savedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SavedLocation &&
          other.id == this.id &&
          other.label == this.label &&
          other.latitude == this.latitude &&
          other.longitude == this.longitude &&
          other.isoCountryCode == this.isoCountryCode &&
          other.utcOffsetHours == this.utcOffsetHours &&
          other.isCurrent == this.isCurrent &&
          other.savedAt == this.savedAt);
}

class SavedLocationsCompanion extends UpdateCompanion<SavedLocation> {
  final Value<int> id;
  final Value<String> label;
  final Value<double> latitude;
  final Value<double> longitude;
  final Value<String?> isoCountryCode;
  final Value<double?> utcOffsetHours;
  final Value<bool> isCurrent;
  final Value<DateTime> savedAt;
  const SavedLocationsCompanion({
    this.id = const Value.absent(),
    this.label = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.isoCountryCode = const Value.absent(),
    this.utcOffsetHours = const Value.absent(),
    this.isCurrent = const Value.absent(),
    this.savedAt = const Value.absent(),
  });
  SavedLocationsCompanion.insert({
    this.id = const Value.absent(),
    required String label,
    required double latitude,
    required double longitude,
    this.isoCountryCode = const Value.absent(),
    this.utcOffsetHours = const Value.absent(),
    this.isCurrent = const Value.absent(),
    this.savedAt = const Value.absent(),
  }) : label = Value(label),
       latitude = Value(latitude),
       longitude = Value(longitude);
  static Insertable<SavedLocation> custom({
    Expression<int>? id,
    Expression<String>? label,
    Expression<double>? latitude,
    Expression<double>? longitude,
    Expression<String>? isoCountryCode,
    Expression<double>? utcOffsetHours,
    Expression<bool>? isCurrent,
    Expression<DateTime>? savedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (label != null) 'label': label,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (isoCountryCode != null) 'iso_country_code': isoCountryCode,
      if (utcOffsetHours != null) 'utc_offset_hours': utcOffsetHours,
      if (isCurrent != null) 'is_current': isCurrent,
      if (savedAt != null) 'saved_at': savedAt,
    });
  }

  SavedLocationsCompanion copyWith({
    Value<int>? id,
    Value<String>? label,
    Value<double>? latitude,
    Value<double>? longitude,
    Value<String?>? isoCountryCode,
    Value<double?>? utcOffsetHours,
    Value<bool>? isCurrent,
    Value<DateTime>? savedAt,
  }) {
    return SavedLocationsCompanion(
      id: id ?? this.id,
      label: label ?? this.label,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isoCountryCode: isoCountryCode ?? this.isoCountryCode,
      utcOffsetHours: utcOffsetHours ?? this.utcOffsetHours,
      isCurrent: isCurrent ?? this.isCurrent,
      savedAt: savedAt ?? this.savedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (latitude.present) {
      map['latitude'] = Variable<double>(latitude.value);
    }
    if (longitude.present) {
      map['longitude'] = Variable<double>(longitude.value);
    }
    if (isoCountryCode.present) {
      map['iso_country_code'] = Variable<String>(isoCountryCode.value);
    }
    if (utcOffsetHours.present) {
      map['utc_offset_hours'] = Variable<double>(utcOffsetHours.value);
    }
    if (isCurrent.present) {
      map['is_current'] = Variable<bool>(isCurrent.value);
    }
    if (savedAt.present) {
      map['saved_at'] = Variable<DateTime>(savedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SavedLocationsCompanion(')
          ..write('id: $id, ')
          ..write('label: $label, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('isoCountryCode: $isoCountryCode, ')
          ..write('utcOffsetHours: $utcOffsetHours, ')
          ..write('isCurrent: $isCurrent, ')
          ..write('savedAt: $savedAt')
          ..write(')'))
        .toString();
  }
}

class $PrayerRecordsTable extends PrayerRecords
    with TableInfo<$PrayerRecordsTable, PrayerRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PrayerRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _dayMeta = const VerificationMeta('day');
  @override
  late final GeneratedColumn<DateTime> day = GeneratedColumn<DateTime>(
    'day',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _prayerMeta = const VerificationMeta('prayer');
  @override
  late final GeneratedColumn<String> prayer = GeneratedColumn<String>(
    'prayer',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 20,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _markedAtMeta = const VerificationMeta(
    'markedAt',
  );
  @override
  late final GeneratedColumn<DateTime> markedAt = GeneratedColumn<DateTime>(
    'marked_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [id, day, prayer, markedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'prayer_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<PrayerRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('day')) {
      context.handle(
        _dayMeta,
        day.isAcceptableOrUnknown(data['day']!, _dayMeta),
      );
    } else if (isInserting) {
      context.missing(_dayMeta);
    }
    if (data.containsKey('prayer')) {
      context.handle(
        _prayerMeta,
        prayer.isAcceptableOrUnknown(data['prayer']!, _prayerMeta),
      );
    } else if (isInserting) {
      context.missing(_prayerMeta);
    }
    if (data.containsKey('marked_at')) {
      context.handle(
        _markedAtMeta,
        markedAt.isAcceptableOrUnknown(data['marked_at']!, _markedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {day, prayer},
  ];
  @override
  PrayerRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PrayerRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      day: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}day'],
      )!,
      prayer: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}prayer'],
      )!,
      markedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}marked_at'],
      )!,
    );
  }

  @override
  $PrayerRecordsTable createAlias(String alias) {
    return $PrayerRecordsTable(attachedDatabase, alias);
  }
}

class PrayerRecord extends DataClass implements Insertable<PrayerRecord> {
  final int id;

  /// Midnight of the day the prayer belongs to.
  final DateTime day;

  /// [Prayer] enum name, stored as text so reordering the enum is harmless.
  final String prayer;
  final DateTime markedAt;
  const PrayerRecord({
    required this.id,
    required this.day,
    required this.prayer,
    required this.markedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['day'] = Variable<DateTime>(day);
    map['prayer'] = Variable<String>(prayer);
    map['marked_at'] = Variable<DateTime>(markedAt);
    return map;
  }

  PrayerRecordsCompanion toCompanion(bool nullToAbsent) {
    return PrayerRecordsCompanion(
      id: Value(id),
      day: Value(day),
      prayer: Value(prayer),
      markedAt: Value(markedAt),
    );
  }

  factory PrayerRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PrayerRecord(
      id: serializer.fromJson<int>(json['id']),
      day: serializer.fromJson<DateTime>(json['day']),
      prayer: serializer.fromJson<String>(json['prayer']),
      markedAt: serializer.fromJson<DateTime>(json['markedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'day': serializer.toJson<DateTime>(day),
      'prayer': serializer.toJson<String>(prayer),
      'markedAt': serializer.toJson<DateTime>(markedAt),
    };
  }

  PrayerRecord copyWith({
    int? id,
    DateTime? day,
    String? prayer,
    DateTime? markedAt,
  }) => PrayerRecord(
    id: id ?? this.id,
    day: day ?? this.day,
    prayer: prayer ?? this.prayer,
    markedAt: markedAt ?? this.markedAt,
  );
  PrayerRecord copyWithCompanion(PrayerRecordsCompanion data) {
    return PrayerRecord(
      id: data.id.present ? data.id.value : this.id,
      day: data.day.present ? data.day.value : this.day,
      prayer: data.prayer.present ? data.prayer.value : this.prayer,
      markedAt: data.markedAt.present ? data.markedAt.value : this.markedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PrayerRecord(')
          ..write('id: $id, ')
          ..write('day: $day, ')
          ..write('prayer: $prayer, ')
          ..write('markedAt: $markedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, day, prayer, markedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PrayerRecord &&
          other.id == this.id &&
          other.day == this.day &&
          other.prayer == this.prayer &&
          other.markedAt == this.markedAt);
}

class PrayerRecordsCompanion extends UpdateCompanion<PrayerRecord> {
  final Value<int> id;
  final Value<DateTime> day;
  final Value<String> prayer;
  final Value<DateTime> markedAt;
  const PrayerRecordsCompanion({
    this.id = const Value.absent(),
    this.day = const Value.absent(),
    this.prayer = const Value.absent(),
    this.markedAt = const Value.absent(),
  });
  PrayerRecordsCompanion.insert({
    this.id = const Value.absent(),
    required DateTime day,
    required String prayer,
    this.markedAt = const Value.absent(),
  }) : day = Value(day),
       prayer = Value(prayer);
  static Insertable<PrayerRecord> custom({
    Expression<int>? id,
    Expression<DateTime>? day,
    Expression<String>? prayer,
    Expression<DateTime>? markedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (day != null) 'day': day,
      if (prayer != null) 'prayer': prayer,
      if (markedAt != null) 'marked_at': markedAt,
    });
  }

  PrayerRecordsCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? day,
    Value<String>? prayer,
    Value<DateTime>? markedAt,
  }) {
    return PrayerRecordsCompanion(
      id: id ?? this.id,
      day: day ?? this.day,
      prayer: prayer ?? this.prayer,
      markedAt: markedAt ?? this.markedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (day.present) {
      map['day'] = Variable<DateTime>(day.value);
    }
    if (prayer.present) {
      map['prayer'] = Variable<String>(prayer.value);
    }
    if (markedAt.present) {
      map['marked_at'] = Variable<DateTime>(markedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PrayerRecordsCompanion(')
          ..write('id: $id, ')
          ..write('day: $day, ')
          ..write('prayer: $prayer, ')
          ..write('markedAt: $markedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $PreferencesTable preferences = $PreferencesTable(this);
  late final $SavedLocationsTable savedLocations = $SavedLocationsTable(this);
  late final $PrayerRecordsTable prayerRecords = $PrayerRecordsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    preferences,
    savedLocations,
    prayerRecords,
  ];
}

typedef $$PreferencesTableCreateCompanionBuilder =
    PreferencesCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$PreferencesTableUpdateCompanionBuilder =
    PreferencesCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$PreferencesTableFilterComposer
    extends Composer<_$AppDatabase, $PreferencesTable> {
  $$PreferencesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PreferencesTableOrderingComposer
    extends Composer<_$AppDatabase, $PreferencesTable> {
  $$PreferencesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PreferencesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PreferencesTable> {
  $$PreferencesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$PreferencesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PreferencesTable,
          Preference,
          $$PreferencesTableFilterComposer,
          $$PreferencesTableOrderingComposer,
          $$PreferencesTableAnnotationComposer,
          $$PreferencesTableCreateCompanionBuilder,
          $$PreferencesTableUpdateCompanionBuilder,
          (
            Preference,
            BaseReferences<_$AppDatabase, $PreferencesTable, Preference>,
          ),
          Preference,
          PrefetchHooks Function()
        > {
  $$PreferencesTableTableManager(_$AppDatabase db, $PreferencesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PreferencesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PreferencesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PreferencesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PreferencesCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => PreferencesCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PreferencesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PreferencesTable,
      Preference,
      $$PreferencesTableFilterComposer,
      $$PreferencesTableOrderingComposer,
      $$PreferencesTableAnnotationComposer,
      $$PreferencesTableCreateCompanionBuilder,
      $$PreferencesTableUpdateCompanionBuilder,
      (
        Preference,
        BaseReferences<_$AppDatabase, $PreferencesTable, Preference>,
      ),
      Preference,
      PrefetchHooks Function()
    >;
typedef $$SavedLocationsTableCreateCompanionBuilder =
    SavedLocationsCompanion Function({
      Value<int> id,
      required String label,
      required double latitude,
      required double longitude,
      Value<String?> isoCountryCode,
      Value<double?> utcOffsetHours,
      Value<bool> isCurrent,
      Value<DateTime> savedAt,
    });
typedef $$SavedLocationsTableUpdateCompanionBuilder =
    SavedLocationsCompanion Function({
      Value<int> id,
      Value<String> label,
      Value<double> latitude,
      Value<double> longitude,
      Value<String?> isoCountryCode,
      Value<double?> utcOffsetHours,
      Value<bool> isCurrent,
      Value<DateTime> savedAt,
    });

class $$SavedLocationsTableFilterComposer
    extends Composer<_$AppDatabase, $SavedLocationsTable> {
  $$SavedLocationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get isoCountryCode => $composableBuilder(
    column: $table.isoCountryCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get utcOffsetHours => $composableBuilder(
    column: $table.utcOffsetHours,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isCurrent => $composableBuilder(
    column: $table.isCurrent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get savedAt => $composableBuilder(
    column: $table.savedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SavedLocationsTableOrderingComposer
    extends Composer<_$AppDatabase, $SavedLocationsTable> {
  $$SavedLocationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get isoCountryCode => $composableBuilder(
    column: $table.isoCountryCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get utcOffsetHours => $composableBuilder(
    column: $table.utcOffsetHours,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isCurrent => $composableBuilder(
    column: $table.isCurrent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get savedAt => $composableBuilder(
    column: $table.savedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SavedLocationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SavedLocationsTable> {
  $$SavedLocationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<double> get latitude =>
      $composableBuilder(column: $table.latitude, builder: (column) => column);

  GeneratedColumn<double> get longitude =>
      $composableBuilder(column: $table.longitude, builder: (column) => column);

  GeneratedColumn<String> get isoCountryCode => $composableBuilder(
    column: $table.isoCountryCode,
    builder: (column) => column,
  );

  GeneratedColumn<double> get utcOffsetHours => $composableBuilder(
    column: $table.utcOffsetHours,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isCurrent =>
      $composableBuilder(column: $table.isCurrent, builder: (column) => column);

  GeneratedColumn<DateTime> get savedAt =>
      $composableBuilder(column: $table.savedAt, builder: (column) => column);
}

class $$SavedLocationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SavedLocationsTable,
          SavedLocation,
          $$SavedLocationsTableFilterComposer,
          $$SavedLocationsTableOrderingComposer,
          $$SavedLocationsTableAnnotationComposer,
          $$SavedLocationsTableCreateCompanionBuilder,
          $$SavedLocationsTableUpdateCompanionBuilder,
          (
            SavedLocation,
            BaseReferences<_$AppDatabase, $SavedLocationsTable, SavedLocation>,
          ),
          SavedLocation,
          PrefetchHooks Function()
        > {
  $$SavedLocationsTableTableManager(
    _$AppDatabase db,
    $SavedLocationsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SavedLocationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SavedLocationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SavedLocationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> label = const Value.absent(),
                Value<double> latitude = const Value.absent(),
                Value<double> longitude = const Value.absent(),
                Value<String?> isoCountryCode = const Value.absent(),
                Value<double?> utcOffsetHours = const Value.absent(),
                Value<bool> isCurrent = const Value.absent(),
                Value<DateTime> savedAt = const Value.absent(),
              }) => SavedLocationsCompanion(
                id: id,
                label: label,
                latitude: latitude,
                longitude: longitude,
                isoCountryCode: isoCountryCode,
                utcOffsetHours: utcOffsetHours,
                isCurrent: isCurrent,
                savedAt: savedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String label,
                required double latitude,
                required double longitude,
                Value<String?> isoCountryCode = const Value.absent(),
                Value<double?> utcOffsetHours = const Value.absent(),
                Value<bool> isCurrent = const Value.absent(),
                Value<DateTime> savedAt = const Value.absent(),
              }) => SavedLocationsCompanion.insert(
                id: id,
                label: label,
                latitude: latitude,
                longitude: longitude,
                isoCountryCode: isoCountryCode,
                utcOffsetHours: utcOffsetHours,
                isCurrent: isCurrent,
                savedAt: savedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SavedLocationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SavedLocationsTable,
      SavedLocation,
      $$SavedLocationsTableFilterComposer,
      $$SavedLocationsTableOrderingComposer,
      $$SavedLocationsTableAnnotationComposer,
      $$SavedLocationsTableCreateCompanionBuilder,
      $$SavedLocationsTableUpdateCompanionBuilder,
      (
        SavedLocation,
        BaseReferences<_$AppDatabase, $SavedLocationsTable, SavedLocation>,
      ),
      SavedLocation,
      PrefetchHooks Function()
    >;
typedef $$PrayerRecordsTableCreateCompanionBuilder =
    PrayerRecordsCompanion Function({
      Value<int> id,
      required DateTime day,
      required String prayer,
      Value<DateTime> markedAt,
    });
typedef $$PrayerRecordsTableUpdateCompanionBuilder =
    PrayerRecordsCompanion Function({
      Value<int> id,
      Value<DateTime> day,
      Value<String> prayer,
      Value<DateTime> markedAt,
    });

class $$PrayerRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $PrayerRecordsTable> {
  $$PrayerRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get prayer => $composableBuilder(
    column: $table.prayer,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get markedAt => $composableBuilder(
    column: $table.markedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PrayerRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $PrayerRecordsTable> {
  $$PrayerRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get prayer => $composableBuilder(
    column: $table.prayer,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get markedAt => $composableBuilder(
    column: $table.markedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PrayerRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PrayerRecordsTable> {
  $$PrayerRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get day =>
      $composableBuilder(column: $table.day, builder: (column) => column);

  GeneratedColumn<String> get prayer =>
      $composableBuilder(column: $table.prayer, builder: (column) => column);

  GeneratedColumn<DateTime> get markedAt =>
      $composableBuilder(column: $table.markedAt, builder: (column) => column);
}

class $$PrayerRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PrayerRecordsTable,
          PrayerRecord,
          $$PrayerRecordsTableFilterComposer,
          $$PrayerRecordsTableOrderingComposer,
          $$PrayerRecordsTableAnnotationComposer,
          $$PrayerRecordsTableCreateCompanionBuilder,
          $$PrayerRecordsTableUpdateCompanionBuilder,
          (
            PrayerRecord,
            BaseReferences<_$AppDatabase, $PrayerRecordsTable, PrayerRecord>,
          ),
          PrayerRecord,
          PrefetchHooks Function()
        > {
  $$PrayerRecordsTableTableManager(_$AppDatabase db, $PrayerRecordsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PrayerRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PrayerRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PrayerRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> day = const Value.absent(),
                Value<String> prayer = const Value.absent(),
                Value<DateTime> markedAt = const Value.absent(),
              }) => PrayerRecordsCompanion(
                id: id,
                day: day,
                prayer: prayer,
                markedAt: markedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime day,
                required String prayer,
                Value<DateTime> markedAt = const Value.absent(),
              }) => PrayerRecordsCompanion.insert(
                id: id,
                day: day,
                prayer: prayer,
                markedAt: markedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PrayerRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PrayerRecordsTable,
      PrayerRecord,
      $$PrayerRecordsTableFilterComposer,
      $$PrayerRecordsTableOrderingComposer,
      $$PrayerRecordsTableAnnotationComposer,
      $$PrayerRecordsTableCreateCompanionBuilder,
      $$PrayerRecordsTableUpdateCompanionBuilder,
      (
        PrayerRecord,
        BaseReferences<_$AppDatabase, $PrayerRecordsTable, PrayerRecord>,
      ),
      PrayerRecord,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$PreferencesTableTableManager get preferences =>
      $$PreferencesTableTableManager(_db, _db.preferences);
  $$SavedLocationsTableTableManager get savedLocations =>
      $$SavedLocationsTableTableManager(_db, _db.savedLocations);
  $$PrayerRecordsTableTableManager get prayerRecords =>
      $$PrayerRecordsTableTableManager(_db, _db.prayerRecords);
}
