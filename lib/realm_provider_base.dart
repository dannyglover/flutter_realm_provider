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

import 'package:realm/realm.dart';

/// realm provider base class
abstract interface class RealmProviderBase {
  /// the realm instance
  late Realm realm;

  // only call when you want to change the schema.
  // see https://stackoverflow.com/a/40593526 for more info
  /// opens a realm database
  void open({
    required List<SchemaObject> schemaList,
    required String path,
    required int schemaVersion,
    List<int>? encryptionKey,
    bool compactOnOpen = false,
    bool runningTests = false,
  });

  // only call when you want to change the schema.
  // see https://stackoverflow.com/a/40593526 for more info
  /// closes a realm database
  void close();

  /// get the first realm object in the table
  T? oldestEntry<T extends RealmObject>();

  /// get the first realm object that matches the given filters
  T? oldestEntryWithFilter<T extends RealmObject>({
    required Map<String, Object> filters,
    required String sortKey,
  });

  /// get the latest realm object in the table
  T? latestEntry<T extends RealmObject>();

  /// get the last realm object that matches the given filters
  T? latestEntryWithFilter<T extends RealmObject>({
    required Map<String, Object> filters,
    required String sortKey,
  });

  /// gets the entry with the specified id
  T? entryWithId<T extends RealmObject>({required Object id});

  /// checks whether the entry with the specified id exists
  bool entryExistsWithId<T extends RealmObject>({required Object id});

  /// gets a list of entries that match the given filters
  List<T>? entriesList<T extends RealmObject>({
    required Map<String, Object> filters,
    required String sortKey,
    required int limit,
    bool ascending = false,
  });

  /// gets a list of entries where any values match the given filters
  List<T>? entriesListWhereAnyIn<T extends RealmObject>({
    required String matchKey,
    required String sortKey,
    required List<Object> values,
    required int limit,
    Map<String, Object>? filters,
    bool ascending = false,
  });

  /// gets a list of entries that match the given search query
  List<T>? entriesListSearch<T extends RealmObject>({
    required Map<String, Object> searchFilters,
    required String sortKey,
    required int limit,
    Map<String, Object>? filters,
    String? distinctKey,
    bool ascending = false,
  });

  /// gets a list of every entry in the database
  List<T>? entriesAllList<T extends RealmObject>();

  /// gets a list of every entry in the database, sorted
  List<T>? entriesAllListSorted<T extends RealmObject>({
    required String sortKey,
    String? distinctKey,
    bool ascending = false,
  });

  /// returns a list of entries found between the two date ranges
  List<T>? entriesInRange<T extends RealmObject>({
    required String matchKey,
    required String dateKey,
    required String sortKey,
    required Object value,
    required DateTime startDate,
    required DateTime endDate,
    bool ascending = false,
  });

  /// removes an entry with the specified id
  void removeEntryWithId<T extends RealmObject>({required Object id});

  /// removes an entry which matches the given filters
  void removeEntryWithFilter<T extends RealmObject>({
    required Map<String, Object> filters,
    required String sortKey,
  });

  /// removes all entries between the two date ranges
  void removeEntriesInRange<T extends RealmObject>({
    required String dateKey,
    required String matchKey,
    required String sortKey,
    required Object value,
    required DateTime startDate,
    required DateTime endDate,
    bool ascending = false,
  });

  /// removes all entries which match the given filters
  void removeAllEntriesWithFilter<T extends RealmObject>({
    required Map<String, Object> filters,
    required String sortKey,
  });

  /// removes all entries from the database
  void removeAllEntries<T extends RealmObject>();

  /// run a parameterized query on the realm object
  RealmResults<T> query<T extends RealmObject>({
    required String query,
    required List<Object>? params,
  });

  /// run a parameterized query on all the realm object
  RealmResults<T> queryAll<T extends RealmObject>({
    required String query,
    required List<Object>? params,
  });

  /// execute a realm write using the callback
  void write({required void Function() callback});
}
