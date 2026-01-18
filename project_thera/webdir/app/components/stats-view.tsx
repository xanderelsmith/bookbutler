import { Book, BookOpen, CheckCircle2, Target, TrendingUp } from "lucide-react";
import { Card } from "./ui/card";
import { Progress } from "./ui/progress";
import { ReadingCalendar } from "./reading-calendar";

interface StatsViewProps {
  totalBooks: number;
  booksReading: number;
  booksCompleted: number;
  booksWantToRead: number;
  totalPagesRead: number;
  currentStreak: number;
}

export function StatsView({
  totalBooks,
  booksReading,
  booksCompleted,
  booksWantToRead,
  totalPagesRead,
  currentStreak,
}: StatsViewProps) {
  const yearlyGoal = 24;
  const goalProgress = (booksCompleted / yearlyGoal) * 100;

  // Mock reading heatmap data
  const readingDays: Record<string, number> = {
    "2026-01-09": 95,
    "2026-01-08": 87,
    "2026-01-07": 102,
    "2026-01-06": 45,
    "2026-01-05": 110,
    "2026-01-04": 78,
    "2026-01-03": 92,
    "2026-01-02": 58,
    "2026-01-01": 120,
    "2025-12-31": 0,
    "2025-12-30": 65,
    "2025-12-29": 88,
    "2025-12-28": 94,
  };

  return (
    <div className="space-y-4 p-4">
      <div>
        <h2 className="text-xl font-semibold text-gray-900 mb-1">Reading Stats</h2>
        <p className="text-sm text-gray-600">Track your reading journey</p>
      </div>

      {/* Reading Goal */}
      <Card className="p-4 bg-gradient-to-br from-purple-500 to-indigo-600 text-white border-0">
        <div className="flex items-center gap-2 mb-3">
          <Target className="size-5" />
          <h3 className="font-semibold">2026 Reading Goal</h3>
        </div>
        <div className="space-y-2">
          <div className="flex justify-between text-sm">
            <span>{booksCompleted} of {yearlyGoal} books</span>
            <span>{Math.round(goalProgress)}%</span>
          </div>
          <Progress value={goalProgress} className="h-2 bg-white/20" />
          <p className="text-xs text-white/90 mt-2">
            {yearlyGoal - booksCompleted} books to go!
          </p>
        </div>
      </Card>

      {/* Stats Grid */}
      <div className="grid grid-cols-2 gap-3">
        <Card className="p-4">
          <div className="flex items-center gap-2 mb-2">
            <div className="p-2 bg-blue-50 rounded-lg">
              <BookOpen className="size-4 text-blue-600" />
            </div>
            <span className="text-xs text-gray-600">Currently Reading</span>
          </div>
          <p className="text-2xl font-semibold text-gray-900">{booksReading}</p>
        </Card>

        <Card className="p-4">
          <div className="flex items-center gap-2 mb-2">
            <div className="p-2 bg-green-50 rounded-lg">
              <CheckCircle2 className="size-4 text-green-600" />
            </div>
            <span className="text-xs text-gray-600">Completed</span>
          </div>
          <p className="text-2xl font-semibold text-gray-900">{booksCompleted}</p>
        </Card>

        <Card className="p-4">
          <div className="flex items-center gap-2 mb-2">
            <div className="p-2 bg-orange-50 rounded-lg">
              <Book className="size-4 text-orange-600" />
            </div>
            <span className="text-xs text-gray-600">Want to Read</span>
          </div>
          <p className="text-2xl font-semibold text-gray-900">{booksWantToRead}</p>
        </Card>

        <Card className="p-4">
          <div className="flex items-center gap-2 mb-2">
            <div className="p-2 bg-purple-50 rounded-lg">
              <TrendingUp className="size-4 text-purple-600" />
            </div>
            <span className="text-xs text-gray-600">Day Streak</span>
          </div>
          <p className="text-2xl font-semibold text-gray-900">{currentStreak}</p>
        </Card>
      </div>

      {/* Pages Read */}
      <Card className="p-4">
        <div className="flex items-center justify-between mb-2">
          <h3 className="font-semibold text-gray-900">Total Pages Read</h3>
          <span className="text-2xl font-bold text-indigo-600">{totalPagesRead.toLocaleString()}</span>
        </div>
        <p className="text-sm text-gray-600">Across {totalBooks} books in your library</p>
      </Card>

      {/* Recent Activity */}
      <Card className="p-4">
        <h3 className="font-semibold text-gray-900 mb-3">This Month</h3>
        <div className="space-y-3">
          <div className="flex justify-between items-center">
            <span className="text-sm text-gray-600">Books Completed</span>
            <span className="font-semibold text-gray-900">3</span>
          </div>
          <div className="flex justify-between items-center">
            <span className="text-sm text-gray-600">Pages Read</span>
            <span className="font-semibold text-gray-900">847</span>
          </div>
          <div className="flex justify-between items-center">
            <span className="text-sm text-gray-600">Avg. Pages/Day</span>
            <span className="font-semibold text-gray-900">94</span>
          </div>
          <div className="flex justify-between items-center">
            <span className="text-sm text-gray-600">Reading Days</span>
            <span className="font-semibold text-gray-900">9 / 9</span>
          </div>
        </div>
      </Card>

      {/* Reading Heatmap */}
      <ReadingCalendar readingDays={readingDays} />
    </div>
  );
}