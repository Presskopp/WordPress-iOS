import XCTest
@testable import WordPress

final class LikeCommentActionTests: XCTestCase {
    private class TestableLikeComment: LikeComment {
        let service: MockNotificationActionsService

        override var actionsService: NotificationActionsService? {
            return service
        }

        init(on: Bool, coreDataStack: CoreDataStack) {
            service = MockNotificationActionsService(managedObjectContext: coreDataStack.mainContext)
            super.init(on: on)
        }
    }

    private class MockNotificationActionsService: NotificationActionsService {
        var likeWasCalled: Bool = false
        var unlikeWasCalled: Bool = false

        override func likeCommentWithBlock(_ block: FormattableCommentContent, completion: ((Bool) -> Void)?) {
            likeWasCalled = true
            completion?(true)
        }

        override func unlikeCommentWithBlock(_ block: FormattableCommentContent, completion: ((Bool) -> Void)?) {
            unlikeWasCalled = true
            completion?(true)
        }
    }

    private var action: LikeComment?
    private let utility = NotificationUtility()
    private var contextManager: ContextManagerMock!

    private struct Constants {
        static let initialStatus: Bool = false
    }

    override func setUp() {
        super.setUp()
        utility.setUp()
        contextManager = ContextManagerMock()
        action = TestableLikeComment(on: Constants.initialStatus, coreDataStack: contextManager)
        makeNetworkAvailable()
    }

    override func tearDown() {
        action = nil
        makeNetworkUnavailable()
        utility.tearDown()
        super.tearDown()
    }

    func testStatusPassedInInitialiserIsPreserved() {
        XCTAssertEqual(action?.on, Constants.initialStatus)
    }

    func testSettingActionOnSetsExpectedTitle() {
        action?.on = true

        XCTAssertEqual(action?.actionTitle, LikeComment.TitleStrings.like)
    }

    func testSettingActionOffSetsExpectedTitle() {
        action?.on = false

        XCTAssertEqual(action?.actionTitle, LikeComment.TitleStrings.unlike)
    }

    func testExecuteCallsUnlikeWhenActionIsOn() throws {
        action?.on = true

        action?.execute(context: try utility.mockCommentContext())

        guard let mockService = action?.actionsService as? MockNotificationActionsService else {
            XCTFail()
            return
        }

        XCTAssertTrue(mockService.unlikeWasCalled)
    }

    func testExecuteUpdatesActionTitleWhenActionIsOn() throws {
        action?.on = true

        action?.execute(context: try utility.mockCommentContext())

        XCTAssertEqual(action?.actionTitle, LikeComment.TitleStrings.like)
    }

    func testExecuteCallsLikeWhenActionIsOff() throws {
        action?.on = false

        action?.execute(context: try utility.mockCommentContext())

        guard let mockService = action?.actionsService as? MockNotificationActionsService else {
            XCTFail()
            return
        }

        XCTAssertTrue(mockService.likeWasCalled)
    }

    func testExecuteUpdatesActionTitleWhenActionIsOff() throws {
        action?.on = false

        action?.execute(context: try utility.mockCommentContext())

        XCTAssertEqual(action?.actionTitle, LikeComment.TitleStrings.unlike)
    }
}
