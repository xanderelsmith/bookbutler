import { Sparkles, Target, TrendingUp, Calendar, Award, Zap } from "lucide-react";
import { Card } from "./ui/card";
import { Badge } from "./ui/badge";
import { BookData } from "./book-card";

interface ButlerInsightsProps {
  books: BookData[];
}

export function ButlerInsights({ books }: ButlerInsightsProps) {
  const booksCompleted = books.filter(b => b.status === "completed").length;
  const booksReading = books.filter(b => b.status === "reading");
  
  const totalPagesRead = books
    .filter(b => b.status === "completed")
    .reduce((sum, b) => sum + b.totalPages, 0);
  
  const averagePagesPerDay = Math.round(totalPagesRead / 9); // 9 days in 2026
  const currentStreak = 9;
  const readingGoal = 24;
  
  const totalReadingTime = books.reduce((sum, b) => sum + (b.totalTimeSpent || 0), 0);
  const averagePagesPerMinute = booksReading.length > 0
    ? booksReading.reduce((sum, b) => sum + (b.pagesPerMinute || 0), 0) / booksReading.length
    : 1.7;

  const daysInYear = 365;
  const daysPassed = 9; // Since we're on Jan 9, 2026
  const projectedBooks = Math.round((booksCompleted / daysPassed) * daysInYear);
  const onTrack = projectedBooks >= readingGoal;

  const insights = [
    {
      icon: Target,
      title: "Goal Projection",
      message: onTrack
        ? `Excellent pace, Sir! At this rate, you'll read ${projectedBooks} books this year, surpassing your goal of ${readingGoal}.`
        : `You're currently on track for ${projectedBooks} books. To reach your goal of ${readingGoal}, increase your pace by ${Math.round(((readingGoal - projectedBooks) / projectedBooks) * 100)}%.`,
      color: onTrack ? "emerald" : "amber",
      highlight: onTrack,
    },
    {
      icon: TrendingUp,
      title: "Reading Velocity",
      message: `Your average reading speed is ${averagePagesPerMinute.toFixed(1)} pages per minute. ${
        averagePagesPerMinute > 1.5
          ? "Remarkable concentration, Sir!"
          : "Consider minimizing distractions to improve focus."
      }`,
      color: "blue",
      highlight: false,
    },
    {
      icon: Zap,
      title: "Consistency Analysis",
      message: currentStreak >= 7
        ? `Outstanding! You've maintained a ${currentStreak}-day reading streak. The habit is solidifying beautifully.`
        : `Your current ${currentStreak}-day streak is promising. Aim for 7 consecutive days to establish a robust habit, Sir.`,
      color: "purple",
      highlight: currentStreak >= 7,
    },
    {
      icon: Calendar,
      title: "Weekly Forecast",
      message: `At your current pace of ${averagePagesPerDay} pages daily, you'll complete approximately ${Math.round(
        averagePagesPerDay * 7 / 300
      )} book(s) this week.`,
      color: "indigo",
      highlight: false,
    },
  ];

  return (
    <div className="space-y-4 p-4">
      {/* Header */}
      <div className="flex items-center gap-3">
        <div className="p-2 bg-gradient-to-br from-purple-500 to-indigo-600 rounded-xl">
          <Sparkles className="size-6 text-white" />
        </div>
        <div>
          <h2 className="text-xl font-semibold text-gray-900">Butler's Insights</h2>
          <p className="text-sm text-gray-600">Your intelligent reading companion</p>
        </div>
      </div>

      {/* Achievement Badge */}
      {currentStreak >= 7 && (
        <Card className="p-4 bg-gradient-to-r from-amber-400 to-orange-500 border-0 text-white">
          <div className="flex items-center gap-3">
            <Award className="size-8" />
            <div>
              <h3 className="font-semibold">Milestone Unlocked!</h3>
              <p className="text-sm text-white/90">
                You've achieved a {currentStreak}-day reading streak. The Butler is most impressed, Sir!
              </p>
            </div>
          </div>
        </Card>
      )}

      {/* Insights */}
      <div className="space-y-3">
        {insights.map((insight, index) => {
          const Icon = insight.icon;
          const colorClasses = {
            emerald: "from-emerald-500 to-teal-600",
            amber: "from-amber-500 to-orange-600",
            blue: "from-blue-500 to-cyan-600",
            purple: "from-purple-500 to-pink-600",
            indigo: "from-indigo-500 to-purple-600",
          };

          return (
            <Card
              key={index}
              className={`p-4 ${
                insight.highlight
                  ? `bg-gradient-to-br ${colorClasses[insight.color as keyof typeof colorClasses]} text-white border-0`
                  : "bg-white border-gray-200"
              }`}
            >
              <div className="flex gap-3">
                <div
                  className={`p-2 rounded-lg h-fit ${
                    insight.highlight
                      ? "bg-white/20"
                      : `bg-${insight.color}-50`
                  }`}
                >
                  <Icon
                    className={`size-5 ${
                      insight.highlight
                        ? "text-white"
                        : `text-${insight.color}-600`
                    }`}
                  />
                </div>
                <div className="flex-1">
                  <h3
                    className={`font-semibold text-sm mb-1 ${
                      insight.highlight ? "text-white" : "text-gray-900"
                    }`}
                  >
                    {insight.title}
                  </h3>
                  <p
                    className={`text-sm ${
                      insight.highlight ? "text-white/90" : "text-gray-600"
                    }`}
                  >
                    {insight.message}
                  </p>
                </div>
              </div>
            </Card>
          );
        })}
      </div>

      {/* Action Items */}
      <Card className="p-4 bg-slate-50 border-slate-200">
        <h3 className="font-semibold text-gray-900 mb-3 flex items-center gap-2">
          <Sparkles className="size-4 text-indigo-600" />
          Suggested Actions
        </h3>
        <div className="space-y-2">
          <div className="flex items-start gap-2">
            <Badge variant="secondary" className="mt-0.5">1</Badge>
            <p className="text-sm text-gray-700">
              Schedule 30 minutes for reading during your peak focus hours (7-9 AM based on your heatmap)
            </p>
          </div>
          <div className="flex items-start gap-2">
            <Badge variant="secondary" className="mt-0.5">2</Badge>
            <p className="text-sm text-gray-700">
              Review your notes from "The Midnight Library" to reinforce key concepts
            </p>
          </div>
          <div className="flex items-start gap-2">
            <Badge variant="secondary" className="mt-0.5">3</Badge>
            <p className="text-sm text-gray-700">
              Share your progress on social media to maintain accountability
            </p>
          </div>
        </div>
      </Card>
    </div>
  );
}