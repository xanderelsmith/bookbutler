import { Card } from "./ui/card";

interface ReadingCalendarProps {
  readingDays: Record<string, number>; // date string -> pages read
}

export function ReadingCalendar({ readingDays }: ReadingCalendarProps) {
  // Generate last 7 weeks (49 days)
  const weeks = 7;
  const daysInWeek = 7;
  const today = new Date("2026-01-09");
  
  const heatmapData: { date: Date; pages: number }[][] = [];
  
  for (let week = 0; week < weeks; week++) {
    const weekData: { date: Date; pages: number }[] = [];
    for (let day = 0; day < daysInWeek; day++) {
      const dateOffset = (weeks - week - 1) * daysInWeek + (daysInWeek - day - 1);
      const date = new Date(today);
      date.setDate(date.getDate() - dateOffset);
      
      const dateStr = date.toISOString().split('T')[0];
      const pages = readingDays[dateStr] || 0;
      weekData.unshift({ date, pages });
    }
    heatmapData.unshift(weekData);
  }

  const getIntensityColor = (pages: number) => {
    if (pages === 0) return "bg-gray-100";
    if (pages < 10) return "bg-emerald-200";
    if (pages < 30) return "bg-emerald-400";
    if (pages < 50) return "bg-emerald-600";
    return "bg-emerald-800";
  };

  const dayLabels = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];

  return (
    <Card className="p-4">
      <h3 className="font-semibold text-gray-900 mb-3">Reading Heatmap</h3>
      <p className="text-xs text-gray-600 mb-4">Your reading activity over the past 7 weeks</p>
      
      <div className="space-y-1">
        {heatmapData.map((week, weekIndex) => (
          <div key={weekIndex} className="flex gap-1">
            {week.map((day, dayIndex) => (
              <div
                key={dayIndex}
                className={`w-6 h-6 rounded-sm ${getIntensityColor(day.pages)} hover:ring-2 hover:ring-indigo-400 cursor-pointer transition-all`}
                title={`${day.date.toLocaleDateString()}: ${day.pages} pages`}
              />
            ))}
          </div>
        ))}
      </div>

      <div className="flex items-center justify-between mt-4 text-xs text-gray-600">
        <span>Less</span>
        <div className="flex gap-1">
          <div className="w-4 h-4 rounded-sm bg-gray-100" />
          <div className="w-4 h-4 rounded-sm bg-emerald-200" />
          <div className="w-4 h-4 rounded-sm bg-emerald-400" />
          <div className="w-4 h-4 rounded-sm bg-emerald-600" />
          <div className="w-4 h-4 rounded-sm bg-emerald-800" />
        </div>
        <span>More</span>
      </div>

      <div className="mt-4 grid grid-cols-7 gap-1 text-xs text-gray-500 text-center">
        {dayLabels.map((label) => (
          <span key={label}>{label}</span>
        ))}
      </div>
    </Card>
  );
}
