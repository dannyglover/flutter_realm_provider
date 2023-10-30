// Flutter_Realm_Provider - Copyright 2023 Danny Glover

import 'package:realm/realm.dart';

abstract interface class RealmProviderBase {
  late Realm realm;

  // only call when you want to change the schema.
  // see https://stackoverflow.com/a/40593526 for more info
  void open(T,
      {required int schemaVersion,
      List<int>? encryptionKey,
      bool runningTests = false});

  // only call when you want to change the schema.
  // see https://stackoverflow.com/a/40593526 for more info
  void close();

  // get the first realm object in the table
  T? oldestEntry<T extends RealmObject>();

  // get the first realm object accociated with this object
  T? oldestEntryWithName<T extends RealmObject>({
    required String matchKey,
    required String sortKey,
    required String name,
  });

  // get the latest realm object in the table
  T? latestEntry<T extends RealmObject>();

  // get the last realm object accociated with this object
  T? latestEntryWithName<T extends RealmObject>({
    required String matchKey,
    required String sortKey,
    required String name,
  });

  // gets the entry with the specified id
  T? entryWithId<T extends RealmObject>({required Object id});

  // gets a list of entries that match the match key
  List<T>? entriesList<T extends RealmObject>(
      {required String matchKey,
      required String sortKey,
      required Object value,
      required int limit,
      bool ascending = false});

  // gets a list of entries where any values match the specified match key
  List<T>? entriesListWhereAny<T extends RealmObject>(
      {required String matchKey,
      required String sortKey,
      required Object[] values,
      required int limit,
      bool ascending = false});

  // gets a list of entries that match the search query
  List<T>? entriesListSearch<T extends RealmObject>(
      {required String matchKey,
      required String sortKey,
      required Object value,
      required int limit,
      String? distinctKey,
      String? secondMatchKey,
      bool ascending = false});

  // gets a list of every entry in the database
  List<T>? entriesAllList<T extends RealmObject>();

  // gets a list of every entry in the database, sorted
  List<T>? entriesAllListSorted<T extends RealmObject>(
      {required String sortKey, required bool ascending});

  // gets a list of every entry in the database with a distinct property, sorted
  List<T>? entriesAllListDistinctSorted<T extends RealmObject>(
      {required String distinctKey,
      required String sortKey,
      required bool ascending});

  // returns a list of entries found between the two date ranges
  List<T>? entriesInRange<T extends RealmObject>(
      {required String matchKey,
      required String sortKey,
      required String name,
      required DateTime startDate,
      required DateTime endDate,
      bool ascending = false});

  // removes an entry with the specified id
  void removeEntryWithId<T extends RealmObject>({required Object id});

  // removes an entry with the specified name
  void removeEntryWithName<T extends RealmObject>(
      {required String matchKey,
      required String sortKey,
      required String name});

  // removes all entries between the two date ranges
  void removeEntriesInRange<T extends RealmObject>(
      {required String matchKey,
      required String sortKey,
      required String name,
      required DateTime startDate,
      required DateTime endDate,
      bool ascending = false});

  // removes all entries from the database with the provided name
  void removeAllEntriesWithName<T extends RealmObject>(
      {required String matchKey,
      required String sortKey,
      required String name});

  // removes all entries from the database
  void removeAllEntries<T extends RealmObject>();

  // run a parameterized query on the realm object
  RealmResults<T> query<T extends RealmObject>(
      String query, List<Object>? params);

  // run a parameterized query on all the realm object
  RealmResults<T> queryAll<T extends RealmObject>(
      String query, List<Object>? params);

  // execute a realm write using the callback
  void write(Function() callback);
}
