import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:otzaria/history/bloc/history_bloc.dart';
import 'package:otzaria/history/bloc/history_event.dart';
import 'package:otzaria/history/bloc/history_state.dart';
import 'package:otzaria/models/books.dart';
import 'package:otzaria/navigation/bloc/navigation_bloc.dart';
import 'package:otzaria/core/scaffold_messenger.dart';
import 'package:otzaria/navigation/bloc/navigation_event.dart';
import 'package:otzaria/navigation/bloc/navigation_state.dart';
import 'package:otzaria/tabs/bloc/tabs_bloc.dart';
import 'package:otzaria/search/bloc/search_event.dart';
import 'package:otzaria/tabs/bloc/tabs_event.dart';
import 'package:otzaria/tabs/models/tab.dart';
import 'package:otzaria/tabs/models/searching_tab.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:otzaria/widgets/items_list_view.dart';

class HistoryView extends StatelessWidget {
  const HistoryView({super.key});

  void _openBook(
      BuildContext context, Book book, int index, List<String>? commentators) {
    final tab = OpenedTab.fromBook(
      book,
      index,
      commentators: commentators,
      openLeftPane: (Settings.getValue<bool>('key-pin-sidebar') ?? false) ||
          (Settings.getValue<bool>('key-default-sidebar-open') ?? false),
    );

    context.read<TabsBloc>().add(AddTab(tab));
    context.read<NavigationBloc>().add(const NavigateToScreen(Screen.reading));
    // Close the dialog if this view is displayed inside one
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  Widget? _getLeadingIcon(Book book, bool isSearch) {
    if (isSearch) {
      return const Icon(Icons.search);
    }
    if (book is PdfBook) {
      if (book.path.toLowerCase().endsWith('.docx')) {
        return const Icon(Icons.description);
      }
      return const Icon(Icons.picture_as_pdf);
    }
    if (book is TextBook) {
      return const Icon(Icons.article);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HistoryBloc, HistoryState>(
      builder: (context, state) {
        if (state is HistoryLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is HistoryError) {
          return Center(child: Text('Error: ${state.message}'));
        }

        return ItemsListView(
          items: state.history,
          onItemTap: (ctx, item, originalIndex) {
            if (item.isSearch) {
              final tabsBloc = ctx.read<TabsBloc>();
              // Always create a new search tab instead of reusing existing one
              final searchTab = SearchingTab('חיפוש', null);
              tabsBloc.add(AddTab(searchTab));

              // Restore search query and options
              searchTab.queryController.text = item.book.title;
              searchTab.searchOptions.clear();
              searchTab.searchOptions.addAll(item.searchOptions ?? {});
              searchTab.alternativeWords.clear();
              searchTab.alternativeWords.addAll(item.alternativeWords ?? {});
              searchTab.spacingValues.clear();
              searchTab.spacingValues.addAll(item.spacingValues ?? {});

              // Trigger search
              searchTab.searchBloc.add(UpdateSearchQuery(
                searchTab.queryController.text,
                customSpacing: searchTab.spacingValues,
                alternativeWords: searchTab.alternativeWords,
                searchOptions: searchTab.searchOptions,
              ));

              // Navigate to search screen
              ctx
                  .read<NavigationBloc>()
                  .add(const NavigateToScreen(Screen.search));
              if (Navigator.of(ctx).canPop()) {
                Navigator.of(ctx).pop();
              }
              return;
            }
            _openBook(ctx, item.book, item.index, item.commentatorsToShow);
          },
          onDelete: (ctx, originalIndex) {
            ctx.read<HistoryBloc>().add(RemoveHistory(originalIndex));
            UiSnack.show('נמחק בהצלחה');
          },
          onClearAll: (ctx) {
            ctx.read<HistoryBloc>().add(ClearHistory());
            UiSnack.show('כל ההיסטוריה נמחקה');
          },
          hintText: 'חפש בהיסטוריה...',
          emptyText: 'אין היסטוריה',
          notFoundText: 'לא נמצאו תוצאות',
          clearAllText: 'מחק את כל ההיסטוריה',
          leadingIconBuilder: (item) =>
              _getLeadingIcon(item.book, item.isSearch),
        );
      },
    );
  }
}
