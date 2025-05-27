import Testing
@testable import FRSync
import FirebaseCore
import FirebaseFirestore
import RealmSwift

enum IntEnum: Int, PersistableEnum {

  case case1, case2
}

enum StringEnum: String, PersistableEnum {

  case case1, case2
}

enum FloatEnum: Float, PersistableEnum {

  case case1, case2
}

enum DoubleEnum: Double, PersistableEnum {

  case case1, case2
}

// int, bool, string, data, date, float, double, object, linking, any, objectid, decimal128, uuid, enum
final class FRObject: Object, SyncingObject, Identifiable {

  @Persisted(primaryKey: true) var id: String

  @Persisted var list: List<String>
  @Persisted var set: MutableSet<String>
  @Persisted var map: Map<String, String>

  @Persisted var int: Int
  @Persisted var bool: Bool
  @Persisted var string: String
  @Persisted var data: Data
  @Persisted var date: Date
  @Persisted var float: Float
  @Persisted var double: Double

  @Persisted var object: FRChildObject!
  @Persisted var embeddedObject: FRChildEmbeddedObject!
  @Persisted var objectId: ObjectId
  @Persisted var decimal: Decimal128
  @Persisted var uuid: UUID

  @Persisted var intEnum: IntEnum
  @Persisted var stringEnum: StringEnum
  @Persisted var floatEnum: FloatEnum
  @Persisted var doubleEnum: DoubleEnum

  @Persisted var syncedAt: Date?

  static func propertyNamesToIgnoreInDocumentData() -> Set<String> {
    return ["id", "object"]
  }
}

final class FRChildObject: Object, SyncingObject, Identifiable {

  @Persisted(primaryKey: true) var id: String
  @Persisted var name: String
  @Persisted var syncedAt: Date?
}

final class FRChildEmbeddedObject: EmbeddedObject, SyncingEmbeddedObject {

  @Persisted var name: String
  @Persisted var syncedAt: Date?
}

let app: FirebaseApp = {
  let options = FirebaseOptions(googleAppID: "1:995943406484:ios:8f101dcdbddee0b1188d81", gcmSenderID: "995943406484")
  options.apiKey = "AIzaSyDtOZo-ZCSa84ZsVTgc3WGSGMxdk-Q50mo"
  options.projectID = "kilotravel-uat"
  FirebaseApp.configure(options: options)
  return FirebaseApp.app()!
}()

@Suite("Doc")
struct Tests {

  let firestore = Firestore.firestore(app: app)

  let realm = try! Realm(configuration: .init(inMemoryIdentifier: "mem"))

  init() {

  }

  @Test func example() async throws {
    let id = "1"

    let list: Array<String> = ["a", "b"]
    let set: Set<String> = ["c", "d"]
    let map: Dictionary<String, String> = ["int": "intvalue", "bool": "boolvalue", "string3": "stringvalue"]

    let int: Int = 1
    let bool: Bool = true
    let string: String = "Text"
    let data: Data = Data()
    let date: Date = Date()
    let float: Float = 1.23
    let double: Double = 5.6789

    let objectValue: [String: Any] = ["name": "object"]
    let embeddedObjectValue: [String: Any] = ["name": "embeddedobject"]
    let objectId: ObjectId = .generate()
    let decimal: Decimal128 = 5.12345
    let uuid: UUID = UUID()

    let intEnum: IntEnum = .case1
    let stringEnum: StringEnum = .case1
    let floatEnum: FloatEnum = .case1
    let doubleEnum: DoubleEnum = .case1

    var personValue: [String: Any] = [:]
    personValue["list"] = list
    personValue["set"] = set
    personValue["map"] = map

    personValue["int"] = int
    personValue["bool"] = bool
    personValue["string"] = string
    personValue["data"] = data
    personValue["date"] = date
    personValue["float"] = float
    personValue["double"] = double

    personValue["object"] = objectValue
    personValue["embeddedObject"] = embeddedObjectValue
    personValue["objectId"] = objectId
    personValue["decimal"] = decimal
    personValue["uuid"] = uuid

    personValue["intEnum"] = intEnum
    personValue["stringEnum"] = stringEnum
    personValue["floatEnum"] = floatEnum
    personValue["doubleEnum"] = doubleEnum

    let person = FRObject(value: personValue)
    try! realm.write {
      realm.add(person)
    }
    #expect(Array<String>(person.list) == list && Set<String>(person.set) == set && Dictionary<String, String>(_immutableCocoaDictionary: person.map) == map)
    #expect(person.int == int && person.bool == bool && person.string == string && person.data == data && person.date == date && person.float == float && person.double == double)
    #expect(person.object.name == objectValue["name"] as! String && person.embeddedObject.name == embeddedObjectValue["name"] as! String && person.objectId == objectId && person.decimal == decimal && person.uuid == uuid)
    #expect(person.intEnum == intEnum && person.stringEnum == stringEnum && person.floatEnum == floatEnum && person.doubleEnum == doubleEnum)

    let snapshot: DocumentSnapshot
    do {
      let documentData = person.documentData()
      print("Document Data: ", documentData)
      let reference = firestore.collection("people").document(id)
      try await reference.setData(documentData)
      snapshot = try await reference.getDocument()

      let snapshotDocumentData = snapshot.data()!
      print("Document Data from Firestore:", snapshotDocumentData)

      let snapshotPersonValue = FRObject.value(documentId: snapshot.documentID, documentData: snapshotDocumentData)
      print("FRObject Value from Firestore:", snapshotPersonValue)

      let snapshotPerson = FRObject(value: snapshotPersonValue)
      print("FRObject from Firestore:", snapshotPerson)

      #expect(snapshotPerson.syncedAt != nil)
      snapshotPerson.syncedAt = nil
//      snapshotPerson.dog?.syncedAt = nil
//      #expect(person == snapshotPerson)
    } catch {
      fatalError(error.localizedDescription)
    }
  }
}

//*/
//typedef NS_CLOSED_ENUM(int32_t, RLMPropertyType) {
//
//  #pragma mark - Primitive types
//  /** Integers: `NSInteger`, `int`, `long`, `Int` (Swift) */
//  RLMPropertyTypeInt    = 0,
//  /** Booleans: `BOOL`, `bool`, `Bool` (Swift) */
//  RLMPropertyTypeBool   = 1,
//  /** Floating-point numbers: `float`, `Float` (Swift) */
//  RLMPropertyTypeFloat  = 5,
//  /** Double-precision floating-point numbers: `double`, `Double` (Swift) */
//  RLMPropertyTypeDouble = 6,
//  /** NSUUID, UUID */
//  RLMPropertyTypeUUID   = 12,
//
//  #pragma mark - Object types
//
//  /** Strings: `NSString`, `String` (Swift) */
//  RLMPropertyTypeString = 2,
//  /** Binary data: `NSData` */
//  RLMPropertyTypeData   = 3,
//  /** Any type: `id<RLMValue>`, `AnyRealmValue` (Swift) */
//  RLMPropertyTypeAny    = 9,
//  /** Dates: `NSDate` */
//  RLMPropertyTypeDate   = 4,
//  RLMPropertyTypeObjectId = 10,
//  RLMPropertyTypeDecimal128 = 11,
//
//  #pragma mark - Linked object types
//
//  /** Realm model objects. See [Realm Models](https://www.mongodb.com/docs/atlas/device-sdks/sdk/swift/model-data/object-models/) for more information. */
//  RLMPropertyTypeObject = 7,
//  /** Realm linking objects. See [Realm Models](https://www.mongodb.com/docs/atlas/device-sdks/sdk/swift/model-data/relationships/#define-an-inverse-relationship-property) for more information. */
//  RLMPropertyTypeLinkingObjects = 8,
//} NS_SWIFT_NAME(PropertyType);
