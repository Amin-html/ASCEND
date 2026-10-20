import 'package:flutter/material.dart';

/// Две части в одну строку: одна слева, другая справа. Если вместе они
/// не помещаются (узкий экран, крупный шрифт), правая часть переносится
/// на следующую строку, а не вылезает за край.
class SplitRow extends StatelessWidget {
  const SplitRow({required this.left, required this.right, super.key});

  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 4,
        children: [left, right],
      ),
    );
  }
}