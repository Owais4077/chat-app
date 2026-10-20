import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relay_messenger/core/theme/app_theme.dart';
void main() { test('provides light and dark themes', () { expect(AppTheme.light().brightness, Brightness.light); expect(AppTheme.dark().brightness, Brightness.dark); }); }
