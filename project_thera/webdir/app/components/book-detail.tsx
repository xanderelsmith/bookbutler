import { X, FileText, BookOpen, Calendar, Hash, Tag } from "lucide-react";
import { Button } from "./ui/button";
import { Progress } from "./ui/progress";
import { Badge } from "./ui/badge";
import { ImageWithFallback } from "./figma/ImageWithFallback";
import { BookData } from "./book-card";

interface BookDetailProps {
  book: BookData;
  onClose: () => void;
  onOpenPdf: () => void;
  onStartSession: (book: BookData) => void;
}

export function BookDetail({ book, onClose, onOpenPdf, onStartSession }: BookDetailProps) {
  return (
    <div className="fixed inset-0 bg-white z-40 overflow-auto">
      {/* Header */}
      <div className="sticky top-0 bg-white/90 backdrop-blur-sm border-b border-gray-200 p-4 z-10">
        <Button variant="ghost" size="icon" onClick={onClose}>
          <X className="size-5" />
        </Button>
      </div>

      {/* Book Cover */}
      <div className="relative">
        <ImageWithFallback
          src={book.cover}
          alt={book.title}
          className="w-full h-80 object-cover"
        />
        <div className="absolute inset-0 bg-gradient-to-t from-black/60 to-transparent" />
      </div>

      {/* Book Info */}
      <div className="px-4 pb-4 -mt-20 relative z-10">
        <div className="bg-white rounded-xl shadow-lg p-5">
          <h1 className="text-2xl font-bold text-gray-900 mb-2">{book.title}</h1>
          <p className="text-gray-600 mb-4">{book.author}</p>

          {book.genre && (
            <div className="flex gap-2 mb-4">
              <Badge variant="secondary">{book.genre}</Badge>
              <Badge variant="outline">Fiction</Badge>
            </div>
          )}

          {/* Progress Section */}
          {book.status === "reading" && (
            <div className="mb-4 p-4 bg-blue-50 rounded-lg">
              <div className="flex justify-between text-sm text-gray-700 mb-2">
                <span className="font-medium">Reading Progress</span>
                <span className="font-semibold">{book.progress}%</span>
              </div>
              <Progress value={book.progress} className="h-2 mb-2" />
              <p className="text-xs text-gray-600">
                {book.currentPage} of {book.totalPages} pages
              </p>
            </div>
          )}

          {/* Book Details */}
          <div className="space-y-3 mb-4">
            <div className="flex items-center gap-3 text-sm">
              <Hash className="size-4 text-gray-400" />
              <span className="text-gray-600">Pages:</span>
              <span className="font-medium text-gray-900">{book.totalPages}</span>
            </div>
            <div className="flex items-center gap-3 text-sm">
              <Calendar className="size-4 text-gray-400" />
              <span className="text-gray-600">Added:</span>
              <span className="font-medium text-gray-900">Jan 5, 2026</span>
            </div>
            <div className="flex items-center gap-3 text-sm">
              <Tag className="size-4 text-gray-400" />
              <span className="text-gray-600">Format:</span>
              <span className="font-medium text-gray-900">PDF</span>
            </div>
          </div>

          {/* Description */}
          <div className="mb-4">
            <h3 className="font-semibold text-gray-900 mb-2">Description</h3>
            <p className="text-sm text-gray-600 leading-relaxed">
              This captivating novel takes readers on an unforgettable journey through time and space. 
              With masterful storytelling and vivid characters, the author weaves a tale that explores 
              the depths of human emotion and the complexities of life's most profound questions.
            </p>
          </div>

          {/* Action Buttons */}
          <div className="space-y-2">
            {book.status === "reading" && (
              <Button className="w-full" onClick={() => onStartSession(book)}>
                <BookOpen className="size-4 mr-2" />
                Start Reading Session
              </Button>
            )}
            {book.pdfUrl && (
              <Button className="w-full" variant="outline" onClick={onOpenPdf}>
                <FileText className="size-4 mr-2" />
                Open PDF
              </Button>
            )}
            {book.status === "want-to-read" && (
              <Button className="w-full">
                <BookOpen className="size-4 mr-2" />
                Start Reading
              </Button>
            )}
          </div>
        </div>
      </div>

      {/* Additional Info */}
      <div className="px-4 pb-24">
        <div className="bg-gray-50 rounded-xl p-4">
          <h3 className="font-semibold text-gray-900 mb-3">Reading Activity</h3>
          <div className="space-y-2 text-sm">
            <div className="flex justify-between">
              <span className="text-gray-600">Last read:</span>
              <span className="font-medium text-gray-900">Today at 2:30 PM</span>
            </div>
            <div className="flex justify-between">
              <span className="text-gray-600">Time spent:</span>
              <span className="font-medium text-gray-900">3h 45m</span>
            </div>
            <div className="flex justify-between">
              <span className="text-gray-600">Pages per session:</span>
              <span className="font-medium text-gray-900">~32 pages</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}