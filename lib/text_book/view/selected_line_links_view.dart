import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:otzaria/models/books.dart';
import 'package:otzaria/models/links.dart';
import 'package:otzaria/tabs/models/tab.dart';
import 'package:otzaria/tabs/models/text_tab.dart';
import 'package:otzaria/text_book/bloc/text_book_bloc.dart';
import 'package:otzaria/text_book/bloc/text_book_state.dart';
import 'package:otzaria/utils/text_manipulation.dart' as utils;

/// Widget שמציג את הקישורים של השורה הנבחרת בלבד
class SelectedLineLinksView extends StatefulWidget {
  final Function(OpenedTab) openBookCallback;
  final double fontSize;
  final bool
      showVisibleLinksIfNoSelection; // האם להציג קישורים נראים אם אין בחירה

  const SelectedLineLinksView({
    super.key,
    required this.openBookCallback,
    required this.fontSize,
    this.showVisibleLinksIfNoSelection = false,
  });

  @override
  State<SelectedLineLinksView> createState() => _SelectedLineLinksViewState();
}

class _SelectedLineLinksViewState extends State<SelectedLineLinksView> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final Map<String, Future<String>> _contentCache = {};
  final Map<String, bool> _expanded = {};
  bool _searchInContent = false;
  Future<List<Link>>? _filteredLinksFuture;
  String _lastSearchKey = '';
  final Set<String> _linksWithSearchResults = {}; // קישורים עם תוצאות חיפוש

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TextBookBloc, TextBookState>(
      builder: (context, state) {
        if (state is! TextBookLoaded) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          children: [
            // שדה חיפוש
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'חפש בתוך הקישורים המוצגים...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                  if (_searchQuery.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Row(
                        children: [
                          Checkbox(
                            value: _searchInContent,
                            onChanged: (value) {
                              setState(() {
                                _searchInContent = value ?? false;
                              });
                            },
                          ),
                          const Text('חפש גם בתוכן הקישורים'),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            // תוכן הקישורים
            Expanded(
              child: _buildLinksList(state),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLinksList(TextBookLoaded state) {
    final links = state.visibleLinks;

    if (links.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'לא נמצאו קישורים לקטע הנבחר',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ),
      );
    }

    // יצירת מפתח ייחודי לחיפוש
    final searchKey = '${_searchQuery}_${_searchInContent}_${links.length}';

    // יצירת Future חדש רק אם החיפוש השתנה
    if (_lastSearchKey != searchKey) {
      _lastSearchKey = searchKey;
      _filteredLinksFuture = _filterLinksAsync(links);
    }

    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: FutureBuilder<List<Link>>(
        future: _filteredLinksFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            );
          }

          final filteredLinks = snapshot.data ?? links;

          return ListView.builder(
            itemCount: filteredLinks.length,
            itemBuilder: (context, index) {
              final link = filteredLinks[index];
              return _buildExpansionTile(link);
            },
          );
        },
      ),
    );
  }

  // פונקציה אסינכרונית לסינון הקישורים עם חיפוש בתוכן
  Future<List<Link>> _filterLinksAsync(List<Link> links) async {
    _linksWithSearchResults.clear(); // איפוס רשימת הקישורים עם תוצאות

    if (_searchQuery.isEmpty) {
      return links;
    }

    final query = _searchQuery.toLowerCase();
    final filteredLinks = <Link>[];

    for (final link in links) {
      final keyStr = '${link.path2}_${link.index2}';
      final title = link.heRef.toLowerCase();
      final bookTitle = utils.getTitleFromPath(link.path2).toLowerCase();

      // חיפוש בכותרת ושם הספר
      if (title.contains(query) || bookTitle.contains(query)) {
        filteredLinks.add(link);
        continue;
      }

      // חיפוש בתוכן אם הופעל
      if (_searchInContent) {
        try {
          final content = await link.content;
          final cleanContent = utils.stripHtmlIfNeeded(content).toLowerCase();
          if (cleanContent.contains(query)) {
            filteredLinks.add(link);
            _linksWithSearchResults.add(keyStr); // מסמן שיש תוצאות בתוכן
            _contentCache[keyStr] = link.content; // טוען את התוכן למטמון

            // פותח אוטומטית את הקישור הראשון עם תוצאות
            if (_linksWithSearchResults.length == 1) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() {
                    _expanded[keyStr] = true;
                  });
                }
              });
            }
          }
        } catch (e) {
          // אם יש שגיאה בטעינת התוכן, מוסיף בכל זאת אם מתאים לכותרת
          // (כבר בדקנו את זה למעלה)
        }
      }
    }

    return filteredLinks;
  }

  Widget _buildExpansionTile(Link link) {
    final keyStr = '${link.path2}_${link.index2}';
    return ExpansionTile(
      key: PageStorageKey(keyStr),
      maintainState: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      collapsedBackgroundColor: Theme.of(context).colorScheme.surface,
      title: Text(
        link.heRef,
        style: TextStyle(
          fontSize: widget.fontSize * 0.75,
          fontWeight: FontWeight.w600,
          fontFamily: 'FrankRuhlCLM',
        ),
      ),
      subtitle: Text(
        utils.getTitleFromPath(link.path2),
        style: TextStyle(
          fontSize: widget.fontSize * 0.65,
          fontFamily: 'FrankRuhlCLM',
          color: Theme.of(context).colorScheme.onSurface.withAlpha(180),
        ),
      ),
      onExpansionChanged: (isExpanded) {
        // טוען תוכן רק אם נפתח ועדיין לא נטען
        if (isExpanded && !_contentCache.containsKey(keyStr)) {
          _contentCache[keyStr] = link.content;
        }

        // עדכון מצב ההרחבה עם setState בטוח
        if (_expanded[keyStr] != isExpanded) {
          setState(() {
            _expanded[keyStr] = isExpanded;
          });
        }
      },
      children: [
        if (_expanded[keyStr] == true)
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: FutureBuilder<String>(
              future: _contentCache[keyStr],
              builder: (context, snapshot) =>
                  _buildLinkContentWidget(link, snapshot),
            ),
          ),
      ],
    );
  }

  Widget _buildLinkContentWidget(Link link, AsyncSnapshot<String> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (snapshot.hasError) {
      return Text(
        'שגיאה בטעינת התוכן: ${snapshot.error}',
        style: TextStyle(
          color: Theme.of(context).colorScheme.error,
          fontSize: widget.fontSize * 0.9,
        ),
      );
    }

    if (!snapshot.hasData || snapshot.data!.isEmpty) {
      return Text(
        'אין תוכן זמין',
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
          fontSize: widget.fontSize * 0.9,
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        widget.openBookCallback(
          TextBookTab(
            book: TextBook(
              title: utils.getTitleFromPath(link.path2),
            ),
            index: link.index2 - 1,
            openLeftPane: (Settings.getValue<bool>('key-pin-sidebar') ??
                    false) ||
                (Settings.getValue<bool>('key-default-sidebar-open') ?? false),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12.0),
        child: _buildHighlightedText(snapshot.data!, link),
      ),
    );
  }

  Widget _buildHighlightedText(String content, Link link) {
    String cleanContent = utils.stripHtmlIfNeeded(content);

    // אם יש חיפוש בתוכן והקישור הזה מכיל תוצאות, מדגיש
    if (_searchQuery.isNotEmpty && _searchInContent) {
      final keyStr = '${link.path2}_${link.index2}';
      if (_linksWithSearchResults.contains(keyStr)) {
        cleanContent = utils.highLight(cleanContent, _searchQuery);
      }
    }

    // אם יש תגי HTML (הדגשה), משתמש ב-HtmlWidget
    if (cleanContent.contains('<font color=')) {
      return HtmlWidget(
        cleanContent,
        textStyle: TextStyle(
          fontSize: widget.fontSize * 0.75,
          height: 1.5,
          fontFamily: 'FrankRuhlCLM',
        ),
      );
    } else {
      // אם אין הדגשה, משתמש ב-Text רגיל
      return Text(
        cleanContent,
        style: TextStyle(
          fontSize: widget.fontSize * 0.75,
          height: 1.5,
          fontFamily: 'FrankRuhlCLM',
        ),
        textAlign: TextAlign.justify,
        textDirection: TextDirection.rtl,
      );
    }
  }
}
