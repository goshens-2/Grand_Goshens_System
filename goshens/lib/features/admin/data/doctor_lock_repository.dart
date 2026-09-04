import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// The "Doctor's use only" passcode gates service pricing and payment
/// records. The first time it is opened the doctor creates + confirms a
/// passcode; afterwards it is required to unlock the feature again.
class DoctorLockRepository {
  DoctorLockRepository(this._supabase);

  final SupabaseClient _supabase;

  String _hash(String passcode) => sha256.convert(utf8.encode(passcode)).toString();

  Future<bool> hasPasscode() async {
    final row = await _supabase.from('doctor_lock').select('id').limit(1).maybeSingle();
    return row != null;
  }

  Future<void> createPasscode(String passcode) async {
    await _supabase.from('doctor_lock').insert({'passcode_hash': _hash(passcode)});
  }

  Future<bool> verifyPasscode(String passcode) async {
    final row = await _supabase.from('doctor_lock').select('passcode_hash').limit(1).maybeSingle();
    if (row == null) return false;
    return row['passcode_hash'] == _hash(passcode);
  }
}

final doctorLockRepositoryProvider = Provider<DoctorLockRepository>((ref) {
  return DoctorLockRepository(Supabase.instance.client);
});
