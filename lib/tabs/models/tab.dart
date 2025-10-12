/* this is a representation of the tabs that could be open in the app.
a tab is either a pdf book or a text book, or a full text search window*/

import 'package:otzaria/tabs/models/pdf_tab.dart';
import 'package:otzaria/tabs/models/searching_tab.dart';
import 'package:otzaria/tabs/models/text_tab.dart';
import 'package:otzaria/models/books.dart';

abstract class OpenedTab {
  String title;
  OpenedTab(this.title);

  /// Called when the tab is being disposed.
  /// Override this method to perform cleanup.
  void dispose() {}

  factory OpenedTab.from(OpenedTab tab) {
    if (tab is TextBookTab) {
      return TextBookTab(
        index: tab.index,
        book: tab.book,
        searchText: tab.searchText,
        commentators: tab.commentators,
      );
    } else if (tab is PdfBookTab) {
      return PdfBookTab(
        book: tab.book,
        pageNumber: tab.pageNumber,
      );
    }
    return tab;
  }

  factory OpenedTab.fromBook(Book book, int index,
      {String searchText = '',
      List<String>? commentators,
      bool openLeftPane = false}) {
    if (book is PdfBook) {
      return PdfBookTab(
        book: book,
        pageNumber: index,
        openLeftPane: openLeftPane,
        searchText: searchText,
      );
    } else if (book is TextBook) {
      return TextBookTab(
        book: book,
        index: index,
        searchText: searchText,
        commentators: commentators,
        openLeftPane: openLeftPane,
      );
    }
    throw UnsupportedError("Unsupported book type: ${book.runtimeType}");
  }

  factory OpenedTab.fromJson(Map<String, dynamic> json) {
    String type = json['type'];
    if (type == 'TextBookTab') {
      return TextBookTab.fromJson(json);
    } else if (type == 'PdfBookTab') {
      return PdfBookTab.fromJson(json);
    }
    return SearchingTab.fromJson(json);
  }
  Map<String, dynamic> toJson();
}
