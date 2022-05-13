import CoreData
import WordPressKit

class BloggingPromptsService {
    private let context: NSManagedObjectContext
    private let siteID: NSNumber
    private let remote: BloggingPromptsServiceRemote
    private let calendar: Calendar = .autoupdatingCurrent

    private var defaultDate: Date {
        calendar.date(byAdding: .day, value: -10, to: Date()) ?? Date()
    }

    /// Fetches a number of blogging prompts starting from the specified date.
    /// When no parameters are specified, this method will attempt to return prompts from ten days ago and two weeks ahead.
    ///
    /// - Parameters:
    ///   - date: When specified, only prompts from the specified date will be returned. Defaults to 10 days ago.
    ///   - number: The amount of prompts to return. Defaults to 24 when unspecified.
    ///   - success: Closure to be called when the fetch process succeeded.
    ///   - failure: Closure to be called when the fetch process failed.
    func fetchPrompts(from date: Date? = nil,
                      number: Int = 24,
                      success: @escaping ([BloggingPrompt]) -> Void,
                      failure: @escaping (Error?) -> Void) {
        let fromDate = date ?? defaultDate
        remote.fetchPrompts(for: siteID, number: number, fromDate: fromDate) { result in
            switch result {
            case .success(let remotePrompts):
                // TODO: Upsert into CoreData once the CoreData model is available.
                success(remotePrompts.map { BloggingPrompt(with: $0) })
            case .failure(let error):
                failure(error)
            }
        }
    }

    /// Convenience method to fetch the blogging prompt for the current day.
    ///
    /// - Parameters:
    ///   - success: Closure to be called when the fetch process succeeded.
    ///   - failure: Closure to be called when the fetch process failed.
    func fetchTodaysPrompt(success: @escaping (BloggingPrompt?) -> Void,
                           failure: @escaping (Error?) -> Void) {
        fetchPrompts(from: Date(), number: 1, success: { (prompts) in
            success(prompts.first)
        }, failure: failure)
    }

    /// Convenience method to fetch the blogging prompts for the Prompts List.
    /// Fetches 11 prompts - the current day and 10 previous.
    ///
    /// - Parameters:
    ///   - success: Closure to be called when the fetch process succeeded.
    ///   - failure: Closure to be called when the fetch process failed.
    func fetchListPrompts(success: @escaping ([BloggingPrompt]) -> Void,
                          failure: @escaping (Error?) -> Void) {
        let fromDate = calendar.date(byAdding: .day, value: -9, to: Date()) ?? Date()
        fetchPrompts(from: fromDate, number: 11, success: success, failure: failure)
    }

    required init?(context: NSManagedObjectContext = ContextManager.shared.mainContext,
                   remote: BloggingPromptsServiceRemote? = nil,
                   blog: Blog? = nil) {
        guard let account = AccountService(managedObjectContext: context).defaultWordPressComAccount(),
              let siteID = blog?.dotComID ?? account.primaryBlogID else {
            return nil
        }

        self.context = context
        self.siteID = siteID
        self.remote = remote ?? .init(wordPressComRestApi: account.wordPressComRestV2Api)
    }
}

// MARK: - Temporary model object

/// TODO: This is a temporary model to be replaced with Core Data model once the fields have all been finalized.
struct BloggingPrompt {
    let promptID: Int
    let text: String
    let title: String // for post title
    let content: String // for post content
    let date: Date
    let answered: Bool
    let answerCount: Int
    let displayAvatarURLs: [URL]
    let attribution: String

    static let examplePrompt = BloggingPrompt(
            promptID: 239,
            text: "Was there a toy or thing you always wanted as a child, during the holidays or on your birthday, but never received? Tell us about it.",
            title: "Prompt number 1",
            content: "<!-- wp:pullquote -->\n<figure class=\"wp-block-pullquote\"><blockquote><p>Was there a toy or thing you always wanted as a child, during the holidays or on your birthday, but never received? Tell us about it.</p><cite>(courtesy of plinky.com)</cite></blockquote></figure>\n<!-- /wp:pullquote -->",
            date: Date(),
            answered: false,
            answerCount: 5,
            displayAvatarURLs: [],
            attribution: "dayone"
    )
}

extension BloggingPrompt {
    init(with remotePrompt: RemoteBloggingPrompt) {
        promptID = remotePrompt.promptID
        text = remotePrompt.text
        title = remotePrompt.title
        content = remotePrompt.content
        date = remotePrompt.date
        answered = remotePrompt.answered
        answerCount = remotePrompt.answeredUsersCount
        displayAvatarURLs = remotePrompt.answeredUserAvatarURLs
        attribution = remotePrompt.attribution
    }
}
