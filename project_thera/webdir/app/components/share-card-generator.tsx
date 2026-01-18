import { X, Download, Share2, Sparkles } from "lucide-react";
import { Button } from "./ui/button";
import { Badge } from "./ui/badge";
import { Textarea } from "./ui/textarea";
import { useState } from "react";
import { ImageWithFallback } from "./figma/ImageWithFallback";
import { BookData } from "./book-card";

interface ShareCardGeneratorProps {
  book: BookData;
  onClose: () => void;
}

export function ShareCardGenerator({ book, onClose }: ShareCardGeneratorProps) {
  const [draftText, setDraftText] = useState(
    `📚 Just finished reading "${book.title}" by ${book.author}!\n\n${
      book.status === "completed"
        ? `Completed all ${book.totalPages} pages. This book taught me about resilience, purpose, and the infinite possibilities of choice.`
        : `Currently ${book.progress}% through (${book.currentPage}/${book.totalPages} pages).`
    }\n\n${
      book.pagesPerMinute
        ? `Reading at ${book.pagesPerMinute.toFixed(1)} pages/min with ${Math.round((book.totalTimeSpent || 0) / 60)}h total invested.`
        : ""
    }\n\n#ReadingChallenge #BookLovers #${book.genre?.replace(/\s+/g, "")}`
  );

  const handleRegenerateDraft = () => {
    // Simulate AI generation with different templates
    const templates = [
      `Just wrapped up "${book.title}" by ${book.author}! ${book.totalPages} pages of pure wisdom. The Butler tracked every moment and it was worth it. 📖✨ #CurrentlyReading`,
      `"${book.title}" is now in my completed shelf! ${book.author} knows how to tell a story. ${book.totalPages} pages flew by. Thanks to The Butler for keeping me on track! 🎯 #BookReview`,
      `Reading update: ${book.progress}% through "${book.title}". ${book.author}'s writing is captivating. The Butler says I'll finish in ${Math.round((book.totalPages - book.currentPage) / 20)} days at my current pace! 📚 #ReadingGoals`,
    ];
    const randomTemplate = templates[Math.floor(Math.random() * templates.length)];
    setDraftText(randomTemplate);
  };

  return (
    <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
      <div className="bg-white rounded-xl w-full max-w-md max-h-[90vh] overflow-auto">
        {/* Header */}
        <div className="p-4 border-b border-gray-200 flex items-center justify-between sticky top-0 bg-white">
          <h2 className="font-semibold text-gray-900">Share Your Progress</h2>
          <Button variant="ghost" size="icon" onClick={onClose}>
            <X className="size-5" />
          </Button>
        </div>

        <div className="p-4 space-y-4">
          {/* Share Card Preview */}
          <div className="bg-gradient-to-br from-indigo-600 to-purple-700 rounded-xl p-6 text-white">
            <div className="flex gap-4 mb-4">
              <ImageWithFallback
                src={book.cover}
                alt={book.title}
                className="w-20 h-28 object-cover rounded-lg shadow-lg"
              />
              <div className="flex-1">
                <h3 className="font-bold text-lg mb-1 line-clamp-2">{book.title}</h3>
                <p className="text-sm text-white/80 mb-2">{book.author}</p>
                {book.status === "completed" && (
                  <Badge className="bg-emerald-500 border-0">✓ Completed</Badge>
                )}
                {book.status === "reading" && (
                  <Badge className="bg-blue-500 border-0">{book.progress}% Read</Badge>
                )}
              </div>
            </div>

            <div className="space-y-2 text-sm">
              <div className="flex justify-between items-center py-2 border-t border-white/20">
                <span className="text-white/80">Progress</span>
                <span className="font-semibold">{book.currentPage} / {book.totalPages} pages</span>
              </div>
              {book.pagesPerMinute && (
                <div className="flex justify-between items-center py-2 border-t border-white/20">
                  <span className="text-white/80">Reading Speed</span>
                  <span className="font-semibold">{book.pagesPerMinute.toFixed(1)} pages/min</span>
                </div>
              )}
              {book.totalTimeSpent && (
                <div className="flex justify-between items-center py-2 border-t border-white/20">
                  <span className="text-white/80">Time Invested</span>
                  <span className="font-semibold">{Math.round(book.totalTimeSpent / 60)}h {book.totalTimeSpent % 60}m</span>
                </div>
              )}
            </div>

            <div className="mt-4 pt-4 border-t border-white/20 text-xs text-white/60 flex items-center justify-between">
              <span>Tracked with The Butler</span>
              <Sparkles className="size-4" />
            </div>
          </div>

          {/* AI-Generated Text */}
          <div>
            <div className="flex items-center justify-between mb-2">
              <label className="text-sm font-medium text-gray-700">Butler's Draft</label>
              <Button
                variant="ghost"
                size="sm"
                onClick={handleRegenerateDraft}
                className="text-xs"
              >
                <Sparkles className="size-3 mr-1" />
                Regenerate
              </Button>
            </div>
            <Textarea
              value={draftText}
              onChange={(e) => setDraftText(e.target.value)}
              rows={8}
              className="text-sm"
            />
            <p className="text-xs text-gray-500 mt-1">
              The Butler has crafted this post based on your reading session. Feel free to edit!
            </p>
          </div>

          {/* Action Buttons */}
          <div className="space-y-2">
            <Button className="w-full" onClick={() => {
              // In a real app, this would trigger native share or download
              alert("Share functionality would integrate with native sharing here!");
            }}>
              <Share2 className="size-4 mr-2" />
              Share to Social Media
            </Button>
            <Button variant="outline" className="w-full" onClick={() => {
              alert("Card image download would happen here!");
            }}>
              <Download className="size-4 mr-2" />
              Download Card Image
            </Button>
          </div>

          <p className="text-xs text-center text-gray-500">
            Share your reading journey and inspire others, Sir!
          </p>
        </div>
      </div>
    </div>
  );
}
