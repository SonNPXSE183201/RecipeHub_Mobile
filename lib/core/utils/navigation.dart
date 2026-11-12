import 'package:flutter/material.dart';
import '../widgets/rh_motion.dart';

void go(BuildContext context, Widget screen) {
  Navigator.push(context, RhPageRoute(builder: (_) => screen));
}
