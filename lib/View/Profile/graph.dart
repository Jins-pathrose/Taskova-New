import 'dart:math';
import 'dart:ui';
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:taskova_new/Model/Analysis/monthlyjobcount.dart';
import 'package:flutter/painting.dart';

class MonthlyJobsChartPainter extends CustomPainter {
  final List<MonthlyJobCount> monthlyJobCounts;
  final Color primaryColor;
  final bool showAll;

  MonthlyJobsChartPainter({
    required this.monthlyJobCounts,
    required this.primaryColor,
    this.showAll = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (monthlyJobCounts.isEmpty) return;

    final maxCount = monthlyJobCounts.map((e) => e.count).reduce(max).toDouble();
    final textStyle = TextStyle(
      color: CupertinoColors.systemGrey,
      fontSize: 10,
    );
    final textPainter = TextPainter(textDirection: ui.TextDirection.ltr);

    // Draw bars
    final barPaint = Paint()
      ..color = primaryColor.withOpacity(0.7)
      ..style = PaintingStyle.fill;

    final shadowPaint = Paint()
      ..color = primaryColor.withOpacity(0.2)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 3);

    if (showAll && monthlyJobCounts.length > 1) {
      // Show all months in a bar chart
      final barWidth = size.width / monthlyJobCounts.length * 0.6;
      final spaceBetween = size.width / monthlyJobCounts.length * 0.4;
      
      for (int i = 0; i < monthlyJobCounts.length; i++) {
        final item = monthlyJobCounts[i];
        final x = i * (barWidth + spaceBetween) + barWidth / 2;
        final barHeight = maxCount > 0 ? (item.count / maxCount) * (size.height - 40) : 0;
        final barTop = size.height - barHeight - 20;

        if (barHeight > 0) {
          // Draw shadow
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(
                (x - barWidth / 2 + 1).toDouble(),
                (barTop + 1).toDouble(),
                barWidth.toDouble(),
                barHeight.toDouble(),
              ),
              Radius.circular(4),
            ),
            shadowPaint,
          );

          // Draw bar
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(
                (x - barWidth / 2).toDouble(),
                barTop.toDouble(),
                barWidth.toDouble(),
                barHeight.toDouble(),
              ),
              Radius.circular(4),
            ),
            barPaint,
          );

          // Draw count text above bar
          final countText = TextSpan(
            text: item.count.toString(),
            style: textStyle.copyWith(
              color: primaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          );
          textPainter.text = countText;
          textPainter.layout();
          textPainter.paint(canvas, Offset(x - textPainter.width / 2, barTop - 15));
        }

        // Draw month label
        final monthParts = item.month.split('-');
        final monthText = TextSpan(
          text: '${monthParts[1]}/${monthParts[0].substring(2)}',
          style: textStyle,
        );
        textPainter.text = monthText;
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(x - textPainter.width / 2, size.height - 15),
        );
      }
    } else {
      // Show single month view - simplified centered design
      final item = monthlyJobCounts.first;
      final centerX = size.width / 2;
      
      // Large number display in center
      final countText = TextSpan(
        text: item.count.toString(),
        style: TextStyle(
          color: primaryColor,
          fontWeight: FontWeight.bold,
          fontSize: 48,
        ),
      );
      textPainter.text = countText;
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(centerX - textPainter.width / 2, size.height / 2 - 40),
      );

      // Jobs text below the number
      final jobText = TextSpan(
        text: item.count == 1 ? 'Job' : 'Jobs',
        style: TextStyle(
          fontSize: 16,
          color: primaryColor.withOpacity(0.8),
          fontWeight: FontWeight.w500,
        ),
      );
      textPainter.text = jobText;
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(centerX - textPainter.width / 2, size.height / 2 + 15),
      );

      // Month name at bottom
      final monthParts = item.month.split('-');
      final monthText = TextSpan(
        text: DateFormat('MMMM yyyy').format(
          DateTime(int.parse(monthParts[0]), int.parse(monthParts[1]))
        ),
        style: TextStyle(
          fontSize: 14,
          color: CupertinoColors.systemGrey,
          fontWeight: FontWeight.w500,
        ),
      );
      textPainter.text = monthText;
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(centerX - textPainter.width / 2, size.height - 20),
      );

      // Optional: Draw a subtle circle background for the number
      final circlePaint = Paint()
        ..color = primaryColor.withOpacity(0.05)
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(
        Offset(centerX, size.height / 2 - 15),
        60,
        circlePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}