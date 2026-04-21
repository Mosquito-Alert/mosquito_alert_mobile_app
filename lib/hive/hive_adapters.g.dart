// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hive_adapters.dart';

// **************************************************************************
// AdaptersGenerator
// **************************************************************************

class OutboxItemAdapter extends TypeAdapter<OutboxItem> {
  @override
  final typeId = 0;

  @override
  OutboxItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return OutboxItem(
      id: fields[0] as String?,
      repository: fields[1] as String,
      operation: fields[2] as OutBoxOperation,
      payload: (fields[3] as Map).cast<String, dynamic>(),
    );
  }

  @override
  void write(BinaryWriter writer, OutboxItem obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.repository)
      ..writeByte(2)
      ..write(obj.operation)
      ..writeByte(3)
      ..write(obj.payload);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OutboxItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class BiteReportAdapter extends TypeAdapter<BiteReport> {
  @override
  final typeId = 1;

  @override
  BiteReport read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BiteReport(
      counts: fields[0] as BiteCounts,
      eventEnvironment: fields[1] as BiteEventEnvironmentEnum?,
      eventMoment: fields[2] as BiteEventMomentEnum?,
      uuid: fields[3] as String?,
      shortId: fields[4] as String?,
      userUuid: fields[5] as String?,
      createdAt: fields[6] as DateTime,
      createdAtLocal: fields[7] as DateTime?,
      sentAt: fields[8] as DateTime?,
      receivedAt: fields[9] as DateTime?,
      updatedAt: fields[10] as DateTime?,
      location: fields[11] as Location,
      note: fields[12] as String?,
      tags: (fields[13] as List?)?.cast<String>(),
      localId: fields[14] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, BiteReport obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.counts)
      ..writeByte(1)
      ..write(obj.eventEnvironment)
      ..writeByte(2)
      ..write(obj.eventMoment)
      ..writeByte(3)
      ..write(obj.uuid)
      ..writeByte(4)
      ..write(obj.shortId)
      ..writeByte(5)
      ..write(obj.userUuid)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.createdAtLocal)
      ..writeByte(8)
      ..write(obj.sentAt)
      ..writeByte(9)
      ..write(obj.receivedAt)
      ..writeByte(10)
      ..write(obj.updatedAt)
      ..writeByte(11)
      ..write(obj.location)
      ..writeByte(12)
      ..write(obj.note)
      ..writeByte(13)
      ..write(obj.tags)
      ..writeByte(14)
      ..write(obj.localId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BiteReportAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class BreedingSiteReportAdapter extends TypeAdapter<BreedingSiteReport> {
  @override
  final typeId = 2;

  @override
  BreedingSiteReport read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BreedingSiteReport(
      siteType: fields[0] as BreedingSiteSiteTypeEnum,
      hasWater: fields[1] as bool?,
      inPublicArea: fields[2] as bool?,
      hasNearMosquitoes: fields[3] as bool?,
      hasLarvae: fields[4] as bool?,
      uuid: fields[6] as String?,
      shortId: fields[7] as String?,
      userUuid: fields[8] as String?,
      createdAt: fields[9] as DateTime,
      createdAtLocal: fields[10] as DateTime?,
      sentAt: fields[11] as DateTime?,
      receivedAt: fields[12] as DateTime?,
      updatedAt: fields[13] as DateTime?,
      location: fields[14] as Location,
      note: fields[15] as String?,
      tags: (fields[16] as List?)?.cast<String>(),
      photos: (fields[5] as List?)?.cast<BasePhoto>(),
      localId: fields[17] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, BreedingSiteReport obj) {
    writer
      ..writeByte(18)
      ..writeByte(0)
      ..write(obj.siteType)
      ..writeByte(1)
      ..write(obj.hasWater)
      ..writeByte(2)
      ..write(obj.inPublicArea)
      ..writeByte(3)
      ..write(obj.hasNearMosquitoes)
      ..writeByte(4)
      ..write(obj.hasLarvae)
      ..writeByte(5)
      ..write(obj.photos)
      ..writeByte(6)
      ..write(obj.uuid)
      ..writeByte(7)
      ..write(obj.shortId)
      ..writeByte(8)
      ..write(obj.userUuid)
      ..writeByte(9)
      ..write(obj.createdAt)
      ..writeByte(10)
      ..write(obj.createdAtLocal)
      ..writeByte(11)
      ..write(obj.sentAt)
      ..writeByte(12)
      ..write(obj.receivedAt)
      ..writeByte(13)
      ..write(obj.updatedAt)
      ..writeByte(14)
      ..write(obj.location)
      ..writeByte(15)
      ..write(obj.note)
      ..writeByte(16)
      ..write(obj.tags)
      ..writeByte(17)
      ..write(obj.localId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BreedingSiteReportAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ObservationReportAdapter extends TypeAdapter<ObservationReport> {
  @override
  final typeId = 3;

  @override
  ObservationReport read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ObservationReport(
      identification: fields[0] as Identification?,
      eventEnvironment: fields[1] as ObservationEventEnvironmentEnum?,
      eventMoment: fields[2] as ObservationEventMomentEnum?,
      uuid: fields[4] as String?,
      shortId: fields[5] as String?,
      userUuid: fields[6] as String?,
      createdAt: fields[7] as DateTime,
      createdAtLocal: fields[8] as DateTime?,
      sentAt: fields[9] as DateTime?,
      receivedAt: fields[10] as DateTime?,
      updatedAt: fields[11] as DateTime?,
      location: fields[12] as Location,
      note: fields[13] as String?,
      tags: (fields[14] as List?)?.cast<String>(),
      photos: (fields[3] as List?)?.cast<BasePhoto>(),
      localId: fields[15] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ObservationReport obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)
      ..write(obj.identification)
      ..writeByte(1)
      ..write(obj.eventEnvironment)
      ..writeByte(2)
      ..write(obj.eventMoment)
      ..writeByte(3)
      ..write(obj.photos)
      ..writeByte(4)
      ..write(obj.uuid)
      ..writeByte(5)
      ..write(obj.shortId)
      ..writeByte(6)
      ..write(obj.userUuid)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.createdAtLocal)
      ..writeByte(9)
      ..write(obj.sentAt)
      ..writeByte(10)
      ..write(obj.receivedAt)
      ..writeByte(11)
      ..write(obj.updatedAt)
      ..writeByte(12)
      ..write(obj.location)
      ..writeByte(13)
      ..write(obj.note)
      ..writeByte(14)
      ..write(obj.tags)
      ..writeByte(15)
      ..write(obj.localId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ObservationReportAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class LocalPhotoAdapter extends TypeAdapter<LocalPhoto> {
  @override
  final typeId = 5;

  @override
  LocalPhoto read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LocalPhoto(fields[0] as String);
  }

  @override
  void write(BinaryWriter writer, LocalPhoto obj) {
    writer
      ..writeByte(1)
      ..writeByte(0)
      ..write(obj.path);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocalPhotoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MemoryPhotoAdapter extends TypeAdapter<MemoryPhoto> {
  @override
  final typeId = 6;

  @override
  MemoryPhoto read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MemoryPhoto(fields[0] as Uint8List);
  }

  @override
  void write(BinaryWriter writer, MemoryPhoto obj) {
    writer
      ..writeByte(1)
      ..writeByte(0)
      ..write(obj.bytes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MemoryPhotoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class OutBoxOperationAdapter extends TypeAdapter<OutBoxOperation> {
  @override
  final typeId = 7;

  @override
  OutBoxOperation read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return OutBoxOperation.create;
      case 1:
        return OutBoxOperation.update;
      case 2:
        return OutBoxOperation.delete;
      default:
        return OutBoxOperation.create;
    }
  }

  @override
  void write(BinaryWriter writer, OutBoxOperation obj) {
    switch (obj) {
      case OutBoxOperation.create:
        writer.writeByte(0);
      case OutBoxOperation.update:
        writer.writeByte(1);
      case OutBoxOperation.delete:
        writer.writeByte(2);
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OutBoxOperationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class FixModelAdapter extends TypeAdapter<FixModel> {
  @override
  final typeId = 8;

  @override
  FixModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FixModel(
      coverageUuid: fields[0] as String,
      createdAt: fields[1] as DateTime,
      sentAt: fields[2] as DateTime?,
      point: fields[3] as FixLocation,
      power: (fields[4] as num?)?.toDouble(),
      localId: fields[5] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, FixModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.coverageUuid)
      ..writeByte(1)
      ..write(obj.createdAt)
      ..writeByte(2)
      ..write(obj.sentAt)
      ..writeByte(3)
      ..write(obj.point)
      ..writeByte(4)
      ..write(obj.power)
      ..writeByte(5)
      ..write(obj.localId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FixModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AuthUserAdapter extends TypeAdapter<AuthUser> {
  @override
  final typeId = 10;

  @override
  AuthUser read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AuthUser(
      password: fields[0] as String,
      username: fields[1] as String?,
      localId: fields[2] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, AuthUser obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.password)
      ..writeByte(1)
      ..write(obj.username)
      ..writeByte(2)
      ..write(obj.localId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthUserAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
