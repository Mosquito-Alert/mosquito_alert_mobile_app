import 'dart:typed_data';
import 'package:hive_ce/hive.dart';
import 'package:built_value/serializer.dart';
import 'package:mosquito_alert/mosquito_alert.dart';
import 'package:mosquito_alert_app/core/outbox/outbox_item.dart';
import 'package:mosquito_alert_app/features/auth/domain/models/auth_user.dart';
import 'package:mosquito_alert_app/features/bites/domain/models/bite_report.dart';
import 'package:mosquito_alert_app/features/breeding_sites/domain/models/breeding_site_report.dart';
import 'package:mosquito_alert_app/features/fixes/domain/models/fix.dart';
import 'package:mosquito_alert_app/features/observations/domain/models/observation_report.dart';
import 'package:mosquito_alert_app/features/reports/domain/models/photo.dart';

@GenerateAdapters(
  [
    AdapterSpec<OutboxItem>(),
    AdapterSpec<OutBoxOperation>(),
    AdapterSpec<BiteReport>(),
    AdapterSpec<BreedingSiteReport>(),
    AdapterSpec<ObservationReport>(),
    AdapterSpec<LocalPhoto>(),
    AdapterSpec<MemoryPhoto>(),
    AdapterSpec<FixModel>(),
    AdapterSpec<AuthUser>(),
  ],
  reservedTypeIds: {100, 101, 102, 103, 104, 105, 106, 107, 108},
)
part 'hive_adapters.g.dart';

class BiteCountsAdapter extends TypeAdapter<BiteCounts> {
  @override
  final int typeId = 100;

  static final _serializer =
      BiteCounts.serializer as PrimitiveSerializer<BiteCounts>;

  @override
  BiteCounts read(BinaryReader reader) {
    // Read the map from the binary reader and convert it to a BiteCounts object
    return _serializer.deserialize(
      serializers,
      reader.read(),
      specifiedType: const FullType(BiteCounts),
    );
  }

  @override
  void write(BinaryWriter writer, BiteCounts obj) {
    writer.write(
      _serializer.serialize(
        serializers,
        obj,
        specifiedType: const FullType(BiteCounts),
      ),
    );
  }
}

class BiteEventEnvironmentEnumAdapter
    extends TypeAdapter<BiteEventEnvironmentEnum> {
  @override
  final int typeId = 101;

  @override
  BiteEventEnvironmentEnum read(BinaryReader reader) {
    final value = reader.readString();
    return BiteEventEnvironmentEnum.valueOf(value);
  }

  @override
  void write(BinaryWriter writer, BiteEventEnvironmentEnum obj) {
    writer.writeString(obj.name);
  }
}

class BiteEventMomentEnumAdapter extends TypeAdapter<BiteEventMomentEnum> {
  @override
  final int typeId = 102;

  @override
  BiteEventMomentEnum read(BinaryReader reader) {
    final value = reader.readString();
    return BiteEventMomentEnum.valueOf(value);
  }

  @override
  void write(BinaryWriter writer, BiteEventMomentEnum obj) {
    writer.writeString(obj.name);
  }
}

class LocationAdapter extends TypeAdapter<Location> {
  @override
  final int typeId = 103;

  static final _serializer =
      Location.serializer as PrimitiveSerializer<Location>;

  @override
  Location read(BinaryReader reader) {
    return _serializer.deserialize(
      serializers,
      reader.read(),
      specifiedType: const FullType(Location),
    );
  }

  @override
  void write(BinaryWriter writer, Location obj) {
    writer.write(
      _serializer.serialize(
        serializers,
        obj,
        specifiedType: const FullType(Location),
      ),
    );
  }
}

class ObservationEventEnvironmentEnumAdapter
    extends TypeAdapter<ObservationEventEnvironmentEnum> {
  @override
  final int typeId = 104;

  @override
  ObservationEventEnvironmentEnum read(BinaryReader reader) {
    final value = reader.readString();
    return ObservationEventEnvironmentEnum.valueOf(value);
  }

  @override
  void write(BinaryWriter writer, ObservationEventEnvironmentEnum obj) {
    writer.writeString(obj.name);
  }
}

class ObservationEventMomentEnumAdapter
    extends TypeAdapter<ObservationEventMomentEnum> {
  @override
  final int typeId = 105;

  @override
  ObservationEventMomentEnum read(BinaryReader reader) {
    final value = reader.readString();
    return ObservationEventMomentEnum.valueOf(value);
  }

  @override
  void write(BinaryWriter writer, ObservationEventMomentEnum obj) {
    writer.writeString(obj.name);
  }
}

class BreedingSiteSiteTypeEnumAdapter
    extends TypeAdapter<BreedingSiteSiteTypeEnum> {
  @override
  final int typeId = 106;

  @override
  BreedingSiteSiteTypeEnum read(BinaryReader reader) {
    final value = reader.readString();
    return BreedingSiteSiteTypeEnum.valueOf(value);
  }

  @override
  void write(BinaryWriter writer, BreedingSiteSiteTypeEnum obj) {
    writer.writeString(obj.name);
  }
}

class FixLocationAdapter extends TypeAdapter<FixLocation> {
  @override
  final int typeId = 107;

  static final _serializer =
      FixLocation.serializer as PrimitiveSerializer<FixLocation>;

  @override
  FixLocation read(BinaryReader reader) {
    return _serializer.deserialize(
      serializers,
      reader.read(),
      specifiedType: const FullType(FixLocation),
    );
  }

  @override
  void write(BinaryWriter writer, FixLocation obj) {
    writer.write(
      _serializer.serialize(
        serializers,
        obj,
        specifiedType: const FullType(FixLocation),
      ),
    );
  }
}

class UserAdapter extends TypeAdapter<User> {
  @override
  final int typeId = 108;

  static final _serializer = User.serializer as PrimitiveSerializer<User>;

  @override
  User read(BinaryReader reader) {
    return _serializer.deserialize(
      serializers,
      reader.read(),
      specifiedType: const FullType(User),
    );
  }

  @override
  void write(BinaryWriter writer, User obj) {
    writer.write(
      _serializer.serialize(
        serializers,
        obj,
        specifiedType: const FullType(User),
      ),
    );
  }
}
