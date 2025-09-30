import 'package:otzaria/data/data_providers/tantivy_data_provider.dart';
import 'package:otzaria/search/search_query_builder.dart';
import 'package:otzaria/search/utils/regex_patterns.dart';
import 'package:search_engine/search_engine.dart';

/// Performs a search operation across indexed texts.
///
/// [query] The search query string
/// [facets] List of facets to search within
/// [limit] Maximum number of results to return
/// [order] Sort order for results
/// [fuzzy] Whether to perform fuzzy matching
/// [distance] Default distance between words (slop)
/// [customSpacing] Custom spacing between specific word pairs
/// [alternativeWords] Alternative words for each word position (OR queries)
/// [searchOptions] Search options for each word (prefixes, suffixes, etc.)
///
/// Returns a Future containing a list of search results
///
class SearchRepository {
  Future<List<SearchResult>> searchTexts(
      String query, List<String> facets, int limit,
      {ResultsOrder order = ResultsOrder.relevance,
      bool fuzzy = false,
      int distance = 2,
      Map<String, String>? customSpacing,
      Map<int, List<String>>? alternativeWords,
      Map<String, Map<String, bool>>? searchOptions}) async {
    print('🚀 searchTexts called with query: "$query"');

    // בדיקת וריאציות כתיב מלא/חסר
    print('🔍 Testing spelling variations for "ראשית":');
    final testVariations =
        SearchRegexPatterns.generateFullPartialSpellingVariations('ראשית');
    print('   variations: $testVariations');

    // בדיקת createPrefixPattern עבור כל וריאציה
    for (final variation in testVariations) {
      final prefixPattern = SearchRegexPatterns.createPrefixPattern(variation);
      print('   $variation -> $prefixPattern');
    }

    // בדיקת createSpellingWithPrefixPattern
    final finalPattern =
        SearchRegexPatterns.createSpellingWithPrefixPattern('ראשית');
    print('🔍 Final createSpellingWithPrefixPattern result: $finalPattern');
    final index = await TantivyDataProvider.instance.engine;

    // בדיקה אם יש מרווחים מותאמים אישית, מילים חילופיות או אפשרויות חיפוש
    final hasCustomSpacing = customSpacing != null && customSpacing.isNotEmpty;
    final hasAlternativeWords =
        alternativeWords != null && alternativeWords.isNotEmpty;
    print('🔍 hasCustomSpacing: $hasCustomSpacing');
    final hasSearchOptions = searchOptions != null &&
        searchOptions.isNotEmpty &&
        searchOptions.values.any((wordOptions) =>
            wordOptions.values.any((isEnabled) => isEnabled == true));

    print('🔍 hasSearchOptions: $hasSearchOptions');
    print('🔍 hasAlternativeWords: $hasAlternativeWords');

    // המרת החיפוש לפורמט המנוע החדש
    print('🔍 Using prepareQueryParams');
    final params = SearchQueryBuilder.prepareQueryParams(
        query, fuzzy, distance, customSpacing, alternativeWords, searchOptions);
    final List<String> regexTerms = params['regexTerms'] as List<String>;
    final int effectiveSlop = params['effectiveSlop'] as int;
    final int maxExpansions = params['maxExpansions'] as int;

    print('🔍 Final search params:');
    print('   regexTerms: $regexTerms');
    print('   facets: $facets');
    print('   limit: $limit');
    print('   slop: $effectiveSlop');
    print('   maxExpansions: $maxExpansions');
    print('🚀 Calling index.search...');

    final results = await index.search(
        regexTerms: regexTerms,
        facets: facets,
        limit: limit,
        slop: effectiveSlop,
        maxExpansions: maxExpansions,
        order: order);

    print('✅ Search completed, found ${results.length} results');
    return results;
  }
}
