import { useState, useEffect } from "react";
import { X, Pause, Play, BookmarkPlus, Clock, TrendingUp, MessageSquare } from "lucide-react";
import { Button } from "./ui/button";
import { Progress } from "./ui/progress";
import { Textarea } from "./ui/textarea";
import { Badge } from "./ui/badge";
import { Card } from "./ui/card";
import { BookData } from "./book-card";

interface ReadingSessionProps {
  book: BookData;
  onClose: () => void;
  onComplete: (page: number, duration: number, notes: string[]) => void;
}

export function ReadingSession({
  book,
  onClose,
  onComplete,
}: ReadingSessionProps) {
  const [isActive, setIsActive] = useState(true);
  const [sessionTime, setSessionTime] = useState(0); // in seconds
  const [startPage, setStartPage] = useState(book.currentPage);
  const [endPage, setEndPage] = useState(book.currentPage);
  const [notes, setNotes] = useState<string[]>([]);
  const [currentNote, setCurrentNote] = useState("");
  const [showNotes, setShowNotes] = useState(false);

  useEffect(() => {
    let interval: NodeJS.Timeout;
    if (isActive) {
      interval = setInterval(() => {
        setSessionTime((time) => time + 1);
      }, 1000);
    }
    return () => clearInterval(interval);
  }, [isActive]);

  const formatTime = (seconds: number) => {
    const hrs = Math.floor(seconds / 3600);
    const mins = Math.floor((seconds % 3600) / 60);
    const secs = seconds % 60;
    if (hrs > 0) {
      return `${hrs}:${mins.toString().padStart(2, "0")}:${secs.toString().padStart(2, "0")}`;
    }
    return `${mins}:${secs.toString().padStart(2, "0")}`;
  };

  const pagesRead = endPage - startPage;
  const pagesPerMinute = sessionTime > 60 ? (pagesRead / (sessionTime / 60)).toFixed(2) : 0;
  const estimatedTimeLeft = pagesPerMinute && Number(pagesPerMinute) > 0
    ? Math.round((book.totalPages - endPage) / Number(pagesPerMinute))
    : 0;

  const handleAddNote = () => {
    if (currentNote.trim()) {
      setNotes([...notes, currentNote]);
      setCurrentNote("");
    }
  };

  const handleEndSession = () => {
    onComplete(endPage, Math.floor(sessionTime / 60), notes);
    onClose();
  };

  return (
    <div className="fixed inset-0 bg-gradient-to-br from-slate-900 to-slate-800 z-50 flex flex-col text-white">
      {/* Header */}
      <div className="p-4 border-b border-slate-700">
        <div className="flex items-center justify-between mb-3">
          <Button variant="ghost" size="icon" onClick={handleEndSession} className="text-white hover:bg-slate-700">
            <X className="size-5" />
          </Button>
          <Badge variant="secondary" className="bg-slate-700">
            <Clock className="size-3 mr-1" />
            {formatTime(sessionTime)}
          </Badge>
        </div>
        <h2 className="font-semibold text-lg">{book.title}</h2>
        <p className="text-sm text-slate-400">{book.author}</p>
      </div>

      {/* Main Content */}
      <div className="flex-1 overflow-auto p-4 space-y-4">
        {/* Session Stats */}
        <Card className="p-4 bg-slate-800 border-slate-700">
          <h3 className="text-sm font-medium text-slate-300 mb-3">Session Performance</h3>
          <div className="grid grid-cols-2 gap-4">
            <div>
              <p className="text-xs text-slate-400">Pages Read</p>
              <p className="text-2xl font-bold text-emerald-400">{pagesRead}</p>
            </div>
            <div>
              <p className="text-xs text-slate-400">Pages/Min</p>
              <p className="text-2xl font-bold text-blue-400">{pagesPerMinute || "—"}</p>
            </div>
            <div>
              <p className="text-xs text-slate-400">Time Remaining</p>
              <p className="text-sm font-medium text-slate-300">
                {estimatedTimeLeft > 0 ? `~${estimatedTimeLeft} mins` : "—"}
              </p>
            </div>
            <div>
              <p className="text-xs text-slate-400">Progress</p>
              <p className="text-sm font-medium text-slate-300">
                {Math.round((endPage / book.totalPages) * 100)}%
              </p>
            </div>
          </div>
        </Card>

        {/* Page Counter */}
        <Card className="p-4 bg-slate-800 border-slate-700">
          <div className="flex items-center justify-between mb-2">
            <label className="text-sm text-slate-300">Current Page</label>
            <input
              type="number"
              value={endPage}
              onChange={(e) => setEndPage(Math.max(startPage, Math.min(book.totalPages, parseInt(e.target.value) || startPage)))}
              className="w-24 px-3 py-2 bg-slate-700 border border-slate-600 rounded-lg text-white text-center"
              min={startPage}
              max={book.totalPages}
            />
          </div>
          <Progress value={(endPage / book.totalPages) * 100} className="h-2" />
          <p className="text-xs text-slate-400 mt-2 text-center">
            {endPage} of {book.totalPages} pages
          </p>
        </Card>

        {/* Butler's Insight */}
        {pagesPerMinute && Number(pagesPerMinute) > 0 && (
          <Card className="p-4 bg-gradient-to-r from-purple-900/50 to-indigo-900/50 border-purple-700">
            <div className="flex gap-3">
              <div className="p-2 bg-purple-800 rounded-full h-fit">
                <TrendingUp className="size-4" />
              </div>
              <div>
                <h4 className="font-medium text-sm mb-1">Butler's Insight</h4>
                <p className="text-xs text-slate-300">
                  At your current pace of {pagesPerMinute} pages/min, you'll finish this book in approximately{" "}
                  <span className="font-semibold text-purple-300">
                    {estimatedTimeLeft < 60 ? `${estimatedTimeLeft} minutes` : `${Math.round(estimatedTimeLeft / 60)} hours`}
                  </span>
                  . Excellent focus, Sir!
                </p>
              </div>
            </div>
          </Card>
        )}

        {/* Notes Section */}
        <Card className="p-4 bg-slate-800 border-slate-700">
          <div className="flex items-center justify-between mb-3">
            <h3 className="text-sm font-medium text-slate-300 flex items-center gap-2">
              <MessageSquare className="size-4" />
              Session Notes
            </h3>
            <Button
              variant="ghost"
              size="sm"
              onClick={() => setShowNotes(!showNotes)}
              className="text-slate-400 hover:text-white"
            >
              {showNotes ? "Hide" : "Show"} ({notes.length})
            </Button>
          </div>

          {showNotes && (
            <div className="space-y-3">
              {notes.map((note, index) => (
                <div key={index} className="p-3 bg-slate-700 rounded-lg text-sm">
                  <p className="text-slate-200">{note}</p>
                  <p className="text-xs text-slate-400 mt-1">Page {endPage}</p>
                </div>
              ))}

              <Textarea
                placeholder="Jot down a thought... The Butler will remember it."
                value={currentNote}
                onChange={(e) => setCurrentNote(e.target.value)}
                className="bg-slate-700 border-slate-600 text-white placeholder:text-slate-400"
                rows={3}
              />
              <Button
                onClick={handleAddNote}
                className="w-full"
                disabled={!currentNote.trim()}
              >
                <BookmarkPlus className="size-4 mr-2" />
                Save Note
              </Button>
            </div>
          )}
        </Card>
      </div>

      {/* Bottom Controls */}
      <div className="p-4 border-t border-slate-700 space-y-3">
        <Button
          variant="outline"
          className="w-full"
          onClick={() => setIsActive(!isActive)}
        >
          {isActive ? (
            <>
              <Pause className="size-4 mr-2" />
              Pause Session
            </>
          ) : (
            <>
              <Play className="size-4 mr-2" />
              Resume Session
            </>
          )}
        </Button>
        <Button onClick={handleEndSession} className="w-full bg-emerald-600 hover:bg-emerald-700">
          End Session & Save Progress
        </Button>
      </div>
    </div>
  );
}