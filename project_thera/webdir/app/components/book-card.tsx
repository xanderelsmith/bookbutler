import { Book, Clock, CheckCircle2, FileText } from "lucide-react";
import { Progress } from "./ui/progress";
import { Badge } from "./ui/badge";
import { ImageWithFallback } from "./figma/ImageWithFallback";

export interface BookData {
  id: string;
  title: string;
  author: string;
  cover: string;
  progress: number;
  totalPages: number;
  currentPage: number;
  status: "reading" | "completed" | "want-to-read";
  pdfUrl?: string;
  genre?: string;
  pagesPerMinute?: number;
  totalTimeSpent?: number; // in minutes
  sessions?: ReadingSession[];
  notes?: Note[];
  dateAdded?: string;
  dateStarted?: string;
  dateCompleted?: string;
}

export interface ReadingSession {
  id: string;
  bookId: string;
  startTime: Date;
  endTime?: Date;
  startPage: number;
  endPage: number;
  duration: number; // in minutes
  pagesRead: number;
  notes?: string[];
}

export interface Note {
  id: string;
  bookId: string;
  page: number;
  content: string;
  timestamp: Date;
  chapter?: string;
}

interface BookCardProps {
  book: BookData;
  onOpen: () => void;
  variant?: "compact" | "full";
}

export function BookCard({ book, onOpen, variant = "full" }: BookCardProps) {
  const getStatusBadge = () => {
    switch (book.status) {
      case "reading":
        return <Badge variant="default" className="bg-blue-500"><Clock className="size-3 mr-1" />Reading</Badge>;
      case "completed":
        return <Badge variant="default" className="bg-green-500"><CheckCircle2 className="size-3 mr-1" />Completed</Badge>;
      case "want-to-read":
        return <Badge variant="secondary"><Book className="size-3 mr-1" />Want to Read</Badge>;
    }
  };

  if (variant === "compact") {
    return (
      <div className="flex gap-3 p-3 bg-white rounded-lg border border-gray-200 cursor-pointer hover:shadow-md transition-shadow" onClick={onOpen}>
        <ImageWithFallback
          src={book.cover}
          alt={book.title}
          className="w-16 h-24 object-cover rounded"
        />
        <div className="flex-1 min-w-0">
          <h3 className="font-semibold text-sm text-gray-900 truncate">{book.title}</h3>
          <p className="text-xs text-gray-600 truncate mb-2">{book.author}</p>
          {book.status === "reading" && (
            <>
              <Progress value={book.progress} className="h-1.5 mb-1" />
              <p className="text-xs text-gray-500">{book.currentPage} / {book.totalPages} pages</p>
            </>
          )}
          {book.status === "completed" && (
            <p className="text-xs text-green-600 flex items-center gap-1 mt-2">
              <CheckCircle2 className="size-3" />
              Finished
            </p>
          )}
        </div>
      </div>
    );
  }

  return (
    <div className="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden cursor-pointer hover:shadow-lg transition-shadow" onClick={onOpen}>
      <div className="relative">
        <ImageWithFallback
          src={book.cover}
          alt={book.title}
          className="w-full h-64 object-cover"
        />
        <div className="absolute top-2 right-2">
          {getStatusBadge()}
        </div>
        {book.pdfUrl && (
          <div className="absolute bottom-2 right-2 bg-white/90 backdrop-blur-sm rounded-full p-2">
            <FileText className="size-4 text-gray-700" />
          </div>
        )}
      </div>
      
      <div className="p-4">
        <h3 className="font-semibold text-gray-900 mb-1 line-clamp-2">{book.title}</h3>
        <p className="text-sm text-gray-600 mb-3">{book.author}</p>
        
        {book.genre && (
          <Badge variant="outline" className="mb-3 text-xs">{book.genre}</Badge>
        )}
        
        {book.status === "reading" && (
          <div className="space-y-2">
            <div className="flex justify-between text-xs text-gray-600">
              <span>{book.progress}% Complete</span>
              <span>{book.currentPage} / {book.totalPages}</span>
            </div>
            <Progress value={book.progress} className="h-2" />
          </div>
        )}
        
        {book.status === "completed" && (
          <div className="flex items-center gap-2 text-sm text-green-600">
            <CheckCircle2 className="size-4" />
            <span>Completed • {book.totalPages} pages</span>
          </div>
        )}
        
        {book.status === "want-to-read" && (
          <div className="text-sm text-gray-500">
            {book.totalPages} pages
          </div>
        )}
      </div>
    </div>
  );
}