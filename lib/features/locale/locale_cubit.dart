import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/constants.dart';
import '../../core/di/injection.dart';

class LocaleCubit extends Cubit<Locale> {
  LocaleCubit() : super(_loadInitial());

  static Locale _loadInitial() {
    final prefs = getIt<SharedPreferences>();
    final value = prefs.getString(AppConstants.keyLocale);
    if (value == 'ar') return const Locale('ar');
    return const Locale('en');
  }

  Future<void> toggleLocale() async {
    final newLocale = state.languageCode == 'en'
        ? const Locale('ar')
        : const Locale('en');
    emit(newLocale);
    final prefs = getIt<SharedPreferences>();
    await prefs.setString(AppConstants.keyLocale, newLocale.languageCode);
  }

  Future<void> setLocale(Locale locale) async {
    emit(locale);
    final prefs = getIt<SharedPreferences>();
    await prefs.setString(AppConstants.keyLocale, locale.languageCode);
  }

  bool get isArabic => state.languageCode == 'ar';
}
