import Foundation
import SwiftData

struct SessionRepository {
    let context: ModelContext

    func insert(_ session: Session) throws {
        context.insert(session)
        try context.save()
    }

    func delete(_ session: Session) throws {
        context.delete(session)
        try context.save()
    }
}
