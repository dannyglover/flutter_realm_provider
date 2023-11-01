// Flutter_Realm_Provider - Copyright 2023 Danny Glover

library flutter_realm_provider;

import 'package:realm/realm.dart';
import 'package:flutter_realm_provider/realm_provider_base.dart';

class RealmProvider implements RealmProviderBase {
  @override
  late Realm realm;
  // When you add or remove new properties to the database
  // you have to change the schema version, so migrations can occur.
  static const int schemaVersion = 1;

  RealmProvider();

  @override
  void open(
    T, {
    required int schemaVersion,
    List<int>? encryptionKey,
    bool runningTests = false,
  }) async {
    if (runningTests) {
      realm = Realm(Configuration.inMemory(T));
      return;
    }

    realm = Realm(Configuration.local(T,
        schemaVersion: schemaVersion, encryptionKey: encryptionKey));
  }

  @override
  void close() {
    if (realm.isClosed) return;

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
    final String filter = filters.entries.map((entry) {
      int index = filters.entries.toList().indexOf(entry);
      return "${entry.key} == \$$index";
    }).join(" AND ");
    final RealmResults<T> results =
        query<T>("$filter SORT($sortKey ASC)", null);

    if (results.isEmpty) return null;

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
    final String filter = filters.entries.map((entry) {
      int index = filters.entries.toList().indexOf(entry);
      return "${entry.key} == \$$index";
    }).join(" AND ");
    final RealmResults<T> results =
        query<T>("$filter SORT($sortKey DESC)", null);

    if (results.isEmpty) return null;

    return results.first;
  }

  // gets the entry with the specified id
  @override
  T? entryWithId<T extends RealmObject>({required Object id}) {
    final RealmResults<T> results = query<T>("id == \$0", [id]);

    if (results.isEmpty) return null;

    return results.first;
  }

  // gets a list of entries that match the filters
  @override
  List<T>? entriesList<T extends RealmObject>({
    required Map<String, Object> filters,
    required String sortKey,
    required int limit,
    bool ascending = false,
  }) {
    final String filter = filters.entries.map((entry) {
      int index = filters.entries.toList().indexOf(entry);
      return "${entry.key} == \$$index";
    }).join(" AND ");
    final String sort = (ascending) ? "ASC" : "DESC";
    final String limitOptions = (limit > 0) ? "LIMIT($limit)" : "";
    final RealmResults<T> results =
        query<T>("$filter SORT($sortKey $sort) $limitOptions", null);

    if (results.isEmpty) return null;

    return results.toList();
  }

  // gets a list of entries where any values match the filters
  @override
  List<T>? entriesListWhereAny<T extends RealmObject>({
    required String matchKey,
    required String sortKey,
    required List<Object> values,
    required int limit,
    bool ascending = false,
  }) {
    final String sort = (ascending) ? "ASC" : "DESC";
    final String limitOptions = (limit > 0) ? "LIMIT($limit)" : "";
    final RealmResults<T> results = query<T>(
        "$matchKey IN \$0 SORT($sortKey $sort) $limitOptions", [values]);

    if (results.isEmpty) return null;

    return results.toList();
  }

  // gets a list of entries that match the search query
  @override
  List<T>? entriesListSearch<T extends RealmObject>({
    required Map<String, Object> filters,
    required String sortKey,
    required int limit,
    String? distinctKey,
    bool ascending = false,
  }) {
    final String sort = (ascending) ? "ASC" : "DESC";
    final String limitOptions = (limit > 0) ? "LIMIT($limit)" : "";
    final String distinctOptions =
        (distinctKey != null) ? "DISTINCT($distinctKey)" : "";
    final String filter = filters.entries.map((entry) {
      int index = filters.entries.toList().indexOf(entry);
      return "${entry.key} LIKE[c] \$$index}";
    }).join(" OR ");
    final RealmResults<T> results = query<T>(
        "$filter SORT($sortKey $sort) $limitOptions $distinctOptions", null);

    if (results.isEmpty) return null;

    return results.toList();
  }

  // gets a list of every entry in the database, sorted
  @override
  List<T>? entriesAllListSorted<T extends RealmObject>({
    required String sortKey,
    required bool ascending,
  }) {
    final String sort = (ascending) ? "ASC" : "DESC";
    final RealmResults<T> results =
        query<T>("TRUEPREDICATE SORT($sortKey $sort)", [""]);

    if (results.isEmpty) return null;

    return results.toList();
  }

  // gets a list of every entry in the database with a distinct property, sorted
  @override
  List<T>? entriesAllListDistinctSorted<T extends RealmObject>({
    required String distinctKey,
    required String sortKey,
    required bool ascending,
  }) {
    final String sort = (ascending) ? "ASC" : "DESC";
    final RealmResults<T> results = query<T>(
        "TRUEPREDICATE SORT($sortKey $sort) DISTINCT($distinctKey)", [""]);

    if (results.isEmpty) return null;

    return results.toList();
  }

  // gets a list of every entry in the database
  @override
  List<T>? entriesAllList<T extends RealmObject>() {
    final RealmResults<T> results = realm.all<T>();

    if (results.isEmpty) return null;

    return results.toList();
  }

  // returns a list of entries found between the two date ranges
  @override
  List<T>? entriesInRange<T extends RealmObject>({
    required String matchKey,
    required String sortKey,
    required String name,
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
          hour: 0, minute: 0, millisecond: 0, microsecond: 0);
      realEndDate = endDate.copyWith(
          hour: 23, minute: 59, millisecond: 0, microsecond: 0);
    }

    final RealmResults<T> results = query<T>(
        "$matchKey == \$0 AND $sortKey BETWEEN{\$1, \$2} SORT($sortKey $sort)",
        [name, realStartDate, realEndDate]);

    if (results.isEmpty) return null;

    return results.toList();
  }

  // removes an entry with the specified id
  @override
  void removeEntryWithId<T extends RealmObject>({required Object id}) {
    final T? result = entryWithId<T>(id: id);

    if (result == null) return;

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

    if (result == null) return;

    realm.write(() {
      realm.delete(result);
    });
  }

  // removes all entries between the two date ranges
  @override
  void removeEntriesInRange<T extends RealmObject>({
    required String matchKey,
    required String sortKey,
    required String name,
    required DateTime startDate,
    required DateTime endDate,
    bool ascending = false,
    bool entireDay = false,
  }) {
    final List<T>? entriesList = entriesInRange<T>(
        matchKey: matchKey,
        sortKey: sortKey,
        name: name,
        startDate: startDate,
        endDate: endDate,
        entireDay: entireDay);

    if (entriesList == null || entriesList.isEmpty) return;

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

    if (results == null || results.isEmpty) return;

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
  RealmResults<T> query<T extends RealmObject>(
      String query, List<Object>? params) {
    if (params == null) return realm.query<T>(query);

    return realm.query<T>(query, params);
  }

  // run a parameterized query on the all items in the database
  @override
  RealmResults<T> queryAll<T extends RealmObject>(
      String query, List<Object>? params) {
    if (params == null) return realm.all<T>().query(query);

    return realm.all<T>().query(query, params);
  }

  // execute a realm write using the callback
  @override
  void write(Function() callback) {
    realm.write(callback);
  }
}
