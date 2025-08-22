import 'package:flutter/material.dart';
import 'package:latext/latext.dart';

List<String> splitTextIntoLatexAndNonLatex(String text) {
  RegExp latexRegex = RegExp(r'(\$(?:[^$]|\\\$)*\$|\$.*?\$|\\\[.*?\\\]|\\\([^)]*\))');
  
  List<String> result = [];
  int lastIndex = 0;
  
  for (var match in latexRegex.allMatches(text)) {
    if (match.start > lastIndex) {
      result.add(text.substring(lastIndex, match.start));
    }
    result.add(match.group(0)!);
    lastIndex = match.end;
  }
  
  if (lastIndex < text.length) {
    result.add(text.substring(lastIndex));
  }
  
  return result;
}

Widget renderTextWithLatex(String text, TextStyle style) {
  List<String> parts = splitTextIntoLatexAndNonLatex(text);
  
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: parts.map((part) {
      if (part.startsWith(r'$') || part.startsWith(r'\[') || part.startsWith(r'\(')) {
        return LaTexT(laTeXCode: Text(part, style: style));
      } else {
        return Text(part, style: style);
      }
    }).toList(),
  );
}
