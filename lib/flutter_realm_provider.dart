/* Flutter Realm Provider: Copyright (C) 2024 Danny Glover

   This program is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by 
   the Free Software Foundation, either version 3 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program. If not, see <https://www.gnu.org/licenses/>
*/

import 'package:flutter_realm_provider/realm_provider_base.dart';
import 'package:realm/realm.dart';

/// used for managing and interacting with a realm database
class RealmProvider implements RealmProviderBase {
  @override
  late Realm realm;

  /// When you add or remove new properties to the database
  /// you have to change the schema version, so migrations can occur.
  static const int schemaVersion = 1;

  @override
  Future<void> open({
    required List<SchemaObject> schemaList,
    required String path,
    required int schemaVersion,
    List<int>? encryptionKey,
    bool runningTests = false,
  }) async {
    if (runningTests) {
      realm = Realm(Configuration.inMemory(schemaList));
      return;
    }

    realm = Realm(
      Configuration.local(
        schemaList,
        path: path,
        schemaVersion: schemaVersion,
        encryptionKey: encryptionKey,
      ),
    );
  }

  @override
  void close() {
    if (realm.isClosed) {
      return;
    }

    realm.close();
  }

  // get the first realm object in the table
  @override
  T? oldestEntry<T extends RealmObject>() {
    return realm.all<T>().firstOrNull;
  }

  // get the first realm object that matches the filters
  @override
  T? oldestEntryWithFilter<T extends RealmObject>({
    required Map<String, Object> filters,
    required String sortKey,
  }) {
    int filterIndex = -1;
    final String filter = filters.entries.map((entry) {
      filterIndex++;
      return "${entry.key} == \$$filterIndex";
    }).join(" AND ");
    final List<Object> values = filters.values.toList();
    final RealmResults<T> results =
        query<T>(query: "$filter SORT($sortKey ASC)", params: [...values]);

    if (results.isEmpty) {
      return null;
    }

    return results.first;
  }

  // get the first realm object in the table
  @override
  T? latestEntry<T extends RealmObject>() {
    return realm.all<T>().lastOrNull;
  }

  // get the last realm object that matches the filters
  @override
  T? latestEntryWithFilter<T extends RealmObject>({
    required Map<String, Object> filters,
    required String sortKey,
  }) {
    int filterIndex = -1;
    final String filter = filters.entries.map((entry) {
      filterIndex++;
      return "${entry.key} == \$$filterIndex";
    }).join(" AND ");
    final List<Object> values = filters.values.toList();
    final RealmResults<T> results =
        query<T>(query: "$filter SORT($sortKey DESC)", params: [...values]);

    if (results.isEmpty) {
      return null;
    }

    return results.first;
  }

  // gets the entry with the specified id
  @override
  T? entryWithId<T extends RealmObject>({required Object id}) {
    final RealmResults<T> results = query<T>(query: "id == \$0", params: [id]);

    if (results.isEmpty) {
      return null;
    }

    return results.first;
  }

  // gets a list of entries that match the filters
  @override
  List<T>? entriesList<T extends RealmObject>({
    required Map<String, Object> filters,
    required String sortKey,
    required int limit,
    String? distinctKey,
    bool ascending = false,
  }) {
    int filterIndex = -1;
    final String filter = filters.entries.map((entry) {
      filterIndex++;
      return "${entry.key} == \$$filterIndex";
    }).join(" AND ");
    final List<Object> values = filters.values.toList();
    final String sort = (ascending) ? "ASC" : "DESC";
    final String limitOptions = (limit > 0) ? "LIMIT($limit)" : "";
    final String distinctOptions =
        (distinctKey != null) ? "DISTINCT($distinctKey)" : "";
    final RealmResults<T> results = query<T>(
      query: "$filter SORT($sortKey $sort) $limitOptions $distinctOptions",
      params: [...values],
    );

    if (results.isEmpty) {
      return null;
    }

    return results.toList();
  }

  // gets a list of entries where any values match the filters
  @override
  List<T>? entriesListWhereAnyIn<T extends RealmObject>({
    required String matchKey,
    required String sortKey,
    required List<Object> values,
    required int limit,
    Map<String, Object>? filters,
    bool ascending = false,
  }) {
    final String sort = (ascending) ? "ASC" : "DESC";
    final String limitOptions = (limit > 0) ? "LIMIT($limit)" : "";
    int filterIndex = -1;
    final String? filter = (filters != null)
        ? filters.entries.map((entry) {
            filterIndex++;
            return "${entry.key} == \$$filterIndex";
          }).join(" AND ")
        : null;
    final List<Object>? filterValues =
        (filters != null) ? filters.values.toList() : null;
    final RealmResults<T>? filteredResults = (filters != null)
        ? query<T>(
            query: "$filter SORT($sortKey $sort) $limitOptions",
            params: [...filterValues!],
          )
        : null;
    final RealmResults<T> results = (filteredResults != null)
        ? filteredResults.query(
            "$matchKey IN \$0 SORT($sortKey $sort) $limitOptions",
            [values],
          )
        : query<T>(
            query: "$matchKey IN \$0 SORT($sortKey $sort) $limitOptions",
            params: [values],
          );

    if (results.isEmpty) {
      return null;
    }

    return results.toList();
  }

  // gets a list of entries that match the search query
  @override
  List<T>? entriesListSearch<T extends RealmObject>({
    required Map<String, Object> searchFilters,
    required String sortKey,
    required int limit,
    Map<String, Object>? filters,
    String? distinctKey,
    bool ascending = false,
  }) {
    int filterIndex = -1;
    int searchFilterIndex = -1;
    final String filter = (filters != null)
        ? filters.entries.map((entry) {
            filterIndex++;
            return "${entry.key} == \$$filterIndex";
          }).join(" AND ")
        : "";
    final String searchFilter = searchFilters.entries.map((entry) {
      searchFilterIndex++;
      return "${entry.key} LIKE[c] \$$searchFilterIndex";
    }).join(" OR ");
    final String sort = (ascending) ? "ASC" : "DESC";
    final String limitOptions = (limit > 0) ? "LIMIT($limit)" : "";
    final String distinctOptions =
        (distinctKey != null) ? "DISTINCT($distinctKey)" : "";
    final List<Object> searchValues = searchFilters.values.toList();
    final List<Object>? filterValues =
        (filters != null) ? filters.values.toList() : null;
    final RealmResults<T>? filteredResults = (filters != null)
        ? query<T>(
            query: "$filter SORT($sortKey $sort) $limitOptions",
            params: [...filterValues!],
          )
        : null;
    final RealmResults<T> results = (filteredResults != null)
        ? filteredResults.query(
            "$searchFilter SORT($sortKey $sort) $limitOptions $distinctOptions",
            [...searchValues],
          )
        : query<T>(
            query: "$searchFilter SORT($sortKey $sort)"
                "$limitOptions $distinctOptions",
            params: [...searchValues],
          );

    if (results.isEmpty) {
      return null;
    }

    return results.toList();
  }

  // gets a list of every entry in the database
  @override
  List<T>? entriesAllList<T extends RealmObject>({
    String? sortKey,
    String? distinctKey,
    bool ascending = false,
  }) {
    final String sort = (ascending) ? "ASC" : "DESC";
    final String sortOptions = (sortKey != null) ? "SORT($sortKey $sort)" : "";
    final String distinctOptions =
        (distinctKey != null) ? "DISTINCT($distinctKey)" : "";
    final RealmResults<T> results = (sortKey != null)
        ? queryAll<T>(query: "$sortOptions $distinctOptions", params: [""])
        : realm.all<T>();

    if (results.isEmpty) {
      return null;
    }

    return results.toList();
  }

  // gets a list of every entry in the database, sorted
  @override
  List<T>? entriesAllListSorted<T extends RealmObject>({
    required String sortKey,
    String? distinctKey,
    bool ascending = false,
  }) {
    final String sort = (ascending) ? "ASC" : "DESC";
    final String distinctOptions =
        (distinctKey != null) ? "DISTINCT($distinctKey)" : "";
    final RealmResults<T> results = query<T>(
      query: "TRUEPREDICATE SORT($sortKey $sort) $distinctOptions",
      params: [""],
    );

    if (results.isEmpty) {
      return null;
    }

    return results.toList();
  }

  // returns a list of entries found between the two date ranges
  @override
  List<T>? entriesInRange<T extends RealmObject>({
    required String matchKey,
    required String dateKey,
    required String sortKey,
    required Object value,
    required DateTime startDate,
    required DateTime endDate,
    bool ascending = false,
    bool entireDay = false,
  }) {
    final String sort = (ascending) ? "ASC" : "DESC";
    DateTime realStartDate = startDate;
    DateTime realEndDate = endDate;

    // start from the beginning of the first day, to the end of the last day
    if (entireDay) {
      realStartDate = startDate.copyWith(
        hour: 0,
        minute: 0,
        millisecond: 0,
        microsecond: 0,
      );
      realEndDate = endDate.copyWith(
        hour: 23,
        minute: 59,
        millisecond: 0,
        microsecond: 0,
      );
    }

    final RealmResults<T> results = query<T>(
      query: "$matchKey == \$0 AND $dateKey"
          "BETWEEN{\$1, \$2} SORT($sortKey $sort)",
      params: [value, realStartDate, realEndDate],
    );

    if (results.isEmpty) {
      return null;
    }

    return results.toList();
  }

  // removes an entry with the specified id
  @override
  void removeEntryWithId<T extends RealmObject>({required Object id}) {
    final T? result = entryWithId<T>(id: id);

    if (result == null) {
      return;
    }

    realm.write(() {
      realm.delete(result);
    });
  }

  // removes an entry which matches the filters
  @override
  void removeEntryWithFilter<T extends RealmObject>({
    required Map<String, Object> filters,
    required String sortKey,
  }) {
    final T? result = latestEntryWithFilter(filters: filters, sortKey: sortKey);

    if (result == null) {
      return;
    }

    realm.write(() {
      realm.delete(result);
    });
  }

  // removes all entries between the two date ranges
  @override
  void removeEntriesInRange<T extends RealmObject>({
    required String dateKey,
    required String matchKey,
    required String sortKey,
    required Object value,
    required DateTime startDate,
    required DateTime endDate,
    bool ascending = false,
    bool entireDay = false,
  }) {
    final List<T>? entriesList = entriesInRange<T>(
      dateKey: dateKey,
      matchKey: matchKey,
      sortKey: sortKey,
      value: value,
      startDate: startDate,
      endDate: endDate,
      entireDay: entireDay,
    );

    if (entriesList == null || entriesList.isEmpty) {
      return;
    }

    realm.write(() {
      realm.deleteMany(entriesList);
    });
  }

  // removes all entries which match the filters
  @override
  void removeAllEntriesWithFilter<T extends RealmObject>({
    required Map<String, Object> filters,
    required String sortKey,
  }) {
    final List<T>? results =
        entriesList(filters: filters, sortKey: sortKey, limit: -1);

    if (results == null || results.isEmpty) {
      return;
    }

    realm.write(() {
      realm.deleteMany(results);
    });
  }

  // removes all entries from the database
  @override
  void removeAllEntries<T extends RealmObject>() {
    realm.write(() {
      realm.deleteAll<T>();
    });
  }

  // run a parameterized query on the database
  @override
  RealmResults<T> query<T extends RealmObject>({
    required String query,
    required List<Object>? params,
  }) {
    if (params == null) {
      return realm.query<T>(query);
    }

    return realm.query<T>(query, params);
  }

  // run a parameterized query on the all items in the database
  @override
  RealmResults<T> queryAll<T extends RealmObject>({
    required String query,
    required List<Object>? params,
  }) {
    if (params == null) {
      return realm.all<T>().query(query);
    }

    return realm.all<T>().query(query, params);
  }

  // execute a realm write using the callback
  @override
  void write({required void Function() callback}) {
    realm.write(callback);
  }
}
