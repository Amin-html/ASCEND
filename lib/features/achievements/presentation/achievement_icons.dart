import 'package:flutter/material.dart';

IconData achievementIcon(String code) => switch (code) {
  'first_step' => Icons.rocket_launch_rounded,
  'streak_7' => Icons.local_fire_department_rounded,
  'tasks_100' => Icons.task_alt_rounded,
  'deep_worker' => Icons.psychology_rounded,
  'goal_crusher' => Icons.emoji_events_rounded,
  'elite' => Icons.military_tech_rounded,
  _ => Icons.star_rounded,
};