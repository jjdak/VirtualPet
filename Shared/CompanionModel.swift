import Combine
import Foundation

enum CompanionMood: String, Codable, CaseIterable {
    case calm
    case bright
    case curious
    case sleepy

    var symbol: String {
        switch self {
        case .calm: "sun.min.fill"
        case .bright: "sun.max.fill"
        case .curious: "sparkles"
        case .sleepy: "moon.stars.fill"
        }
    }

    var accessibilityDescription: String {
        switch self {
        case .calm: "平静"
        case .bright: "开心"
        case .curious: "好奇"
        case .sleepy: "困倦"
        }
    }
}

enum CompanionHitRegion: String, Codable, CaseIterable {
    case hat
    case head
    case body
}

enum CompanionReaction: String, Codable, CaseIterable {
    case idle
    case hatTouch
    case headPat
    case bodyPoke
    case rapidTap
    case longPress
    case chirp
    case sleepy

    var symbol: String? {
        switch self {
        case .idle: nil
        case .hatTouch: "questionmark"
        case .headPat: "heart.fill"
        case .bodyPoke: "exclamationmark"
        case .rapidTap: "bolt.fill"
        case .longPress: "arrow.down"
        case .chirp: "music.note"
        case .sleepy: "zzz"
        }
    }

    var accessibilityDescription: String {
        switch self {
        case .idle: "待机"
        case .hatTouch: "帽子被碰了一下"
        case .headPat: "被摸摸头"
        case .bodyPoke: "身体被戳了一下"
        case .rapidTap: "被连续戳了好几下"
        case .longPress: "被按扁了"
        case .chirp: "开心地啾比"
        case .sleepy: "有点困了"
        }
    }
}

enum DayPhase: String {
    case morning
    case afternoon
    case evening
    case night

    init(date: Date, calendar: Calendar = .current) {
        switch calendar.component(.hour, from: date) {
        case 5..<12: self = .morning
        case 12..<17: self = .afternoon
        case 17..<22: self = .evening
        default: self = .night
        }
    }

    var label: String {
        switch self {
        case .morning: "清晨"
        case .afternoon: "午后"
        case .evening: "黄昏"
        case .night: "夜深了"
        }
    }

    var openingLine: String {
        switch self {
        case .morning: "早呀。今天的阳光，我先替你尝过啦。"
        case .afternoon: "终于来了？我都快把云数完了。"
        case .evening: "辛苦啦。今天的麻烦先寄存在我这里。"
        case .night: "还不睡？我可没答应替你守一整夜。"
        }
    }

    var idleLine: String {
        switch self {
        case .morning: "嗯，今天会有好事发生。"
        case .afternoon: "发什么呆呢？我可都看见了。"
        case .evening: "歇一会儿也不算偷懒。"
        case .night: "再陪你一小会儿，就一小会儿。"
        }
    }

    var initialMood: CompanionMood {
        self == .night ? .sleepy : .calm
    }

    var idleReaction: CompanionReaction {
        self == .night ? .sleepy : .idle
    }
}

@MainActor
final class CompanionStore: ObservableObject {
    @Published private(set) var mood: CompanionMood
    @Published private(set) var reaction: CompanionReaction
    @Published private(set) var message: String
    @Published private(set) var reactionID = UUID()
    @Published var isQuietMode: Bool {
        didSet {
            defaults.set(isQuietMode, forKey: Keys.quietMode)
            recentTapTimes.removeAll()
            resetTask?.cancel()

            if isQuietMode {
                setMoment(
                    reaction: .idle,
                    mood: .calm,
                    message: "好吧，安静模式。你不说话，我也不催你。"
                )
            } else {
                settle()
            }
        }
    }

    let phase: DayPhase

    private let defaults: UserDefaults
    private var responseIndex = 0
    private var recentTapTimes: [Date] = []
    private var resetTask: Task<Void, Never>?

    init(
        defaults: UserDefaults = .standard,
        now: Date = .now,
        calendar: Calendar = .current
    ) {
        let phase = DayPhase(date: now, calendar: calendar)
        self.defaults = defaults
        self.phase = phase
        self.mood = phase.initialMood
        self.reaction = phase.idleReaction
        self.message = phase.openingLine
        self.isQuietMode = defaults.bool(forKey: Keys.quietMode)

        if self.isQuietMode {
            self.mood = .calm
            self.reaction = .idle
            self.message = "我在这里。今天不用完成任何任务。"
        }
    }

    func respond() {
        guard !isQuietMode else {
            trigger(
                reaction: .headPat,
                mood: .calm,
                message: "嗯，我听见了。小声一点也没关系。"
            )
            return
        }

        let responses: [(CompanionReaction, CompanionMood, String)] = [
            (.chirp, .bright, "菲比啾比！这声招呼还算有精神。"),
            (.hatTouch, .curious, "叫我做什么？先说好，不许安排麻烦事。"),
            (.headPat, .bright, "你来得正好，我刚想找个人夸夸我。"),
            (.bodyPoke, .curious, "我在认真陪伴，你却在研究按钮？")
        ]

        let response = responses[responseIndex % responses.count]
        responseIndex += 1
        trigger(reaction: response.0, mood: response.1, message: response.2)
    }

    func touch(_ region: CompanionHitRegion, at date: Date = .now) {
        recentTapTimes.removeAll {
            let age = date.timeIntervalSince($0)
            return age < 0 || age > Constants.rapidTapWindow
        }
        recentTapTimes.append(date)

        if recentTapTimes.count >= Constants.rapidTapCount {
            recentTapTimes.removeAll()
            trigger(
                reaction: .rapidTap,
                mood: .curious,
                message: isQuietMode
                    ? "连续三下。你是在确认我还在吗？"
                    : "再戳就要收共鸣税啦！"
            )
            return
        }

        switch region {
        case .hat:
            trigger(
                reaction: .hatTouch,
                mood: .curious,
                message: isQuietMode
                    ? "帽子碰歪了……一点点。"
                    : "帽子不是按钮——不过这次原谅你。"
            )
        case .head:
            trigger(
                reaction: .headPat,
                mood: .bright,
                message: isQuietMode
                    ? "轻轻的，收到了。"
                    : "嗯……手法勉强合格，再摸一下也不是不行。"
            )
        case .body:
            trigger(
                reaction: .bodyPoke,
                mood: .curious,
                message: isQuietMode
                    ? "我在。别戳丢了。"
                    : "你是不是把我当成会说话的按钮了？"
            )
        }
    }

    func longPress() {
        recentTapTimes.removeAll()
        trigger(
            reaction: .longPress,
            mood: .curious,
            message: isQuietMode
                ? "压扁了……但我不吵。"
                : "放——手——我快变成菲比饼啦！"
        )
    }

    func chirp() {
        recentTapTimes.removeAll()
        trigger(
            reaction: .chirp,
            mood: .bright,
            message: isQuietMode
                ? "小声地……菲比啾比。"
                : "菲比啾比！今天也要分你一点好心情。"
        )
    }

    private func trigger(
        reaction: CompanionReaction,
        mood: CompanionMood,
        message: String
    ) {
        resetTask?.cancel()
        setMoment(reaction: reaction, mood: mood, message: message)
        let eventID = reactionID

        resetTask = Task { @MainActor [weak self] in
            do {
                try await Task.sleep(nanoseconds: Constants.reactionDuration)
            } catch {
                return
            }

            guard let self, self.reactionID == eventID else { return }
            self.settle()
        }
    }

    private func settle() {
        setMoment(
            reaction: phase.idleReaction,
            mood: phase.initialMood,
            message: isQuietMode ? "我在这里。什么都不做也可以。" : phase.idleLine
        )
    }

    private func setMoment(
        reaction: CompanionReaction,
        mood: CompanionMood,
        message: String
    ) {
        self.reaction = reaction
        self.mood = mood
        self.message = message
        self.reactionID = UUID()
    }

    private enum Keys {
        static let quietMode = "companion.quietMode"
    }

    private enum Constants {
        static let rapidTapWindow: TimeInterval = 0.72
        static let rapidTapCount = 3
        static let reactionDuration: UInt64 = 1_650_000_000
    }
}
