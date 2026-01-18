import { useState } from "react";
import { Home, Library, BarChart3, Plus, Search, Sparkles } from "lucide-react";
import { BookCard, BookData } from "./components/book-card";
import { StatsView } from "./components/stats-view";
import { PdfReader } from "./components/pdf-reader";
import { BookDetail } from "./components/book-detail";
import { ReadingSession } from "./components/reading-session";
import { ButlerInsights } from "./components/butler-insights";
import { ShareCardGenerator } from "./components/share-card-generator";
import { Button } from "./components/ui/button";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "./components/ui/tabs";
import { Input } from "./components/ui/input";
import { Toaster } from "./components/ui/sonner";
import { toast } from "sonner";

export default function App() {
  const [currentView, setCurrentView] = useState<"home" | "library" | "stats">("home");
  const [selectedBook, setSelectedBook] = useState<BookData | null>(null);
  const [showPdfReader, setShowPdfReader] = useState(false);
  const [showBookDetail, setShowBookDetail] = useState(false);
  const [showReadingSession, setShowReadingSession] = useState(false);
  const [showShareCard, setShowShareCard] = useState(false);
  const [searchQuery, setSearchQuery] = useState("");

  // Mock book data
  const [books, setBooks] = useState<BookData[]>([
    {
      id: "1",
      title: "The Midnight Library",
      author: "Matt Haig",
      cover: "https://images.unsplash.com/photo-1636262454420-364d3a97e3e7?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxib29rJTIwY292ZXIlMjBub3ZlbHxlbnwxfHx8fDE3Njc5NTMxOTR8MA&ixlib=rb-4.1.0&q=80&w=1080",
      progress: 68,
      totalPages: 304,
      currentPage: 207,
      status: "reading",
      pdfUrl: "/sample.pdf",
      genre: "Fantasy",
      pagesPerMinute: 1.8,
      totalTimeSpent: 225, // minutes
      dateAdded: "2026-01-02",
      dateStarted: "2026-01-03",
    },
    {
      id: "2",
      title: "Atomic Habits",
      author: "James Clear",
      cover: "https://images.unsplash.com/photo-1707142979946-a745d1d0092c?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxyZWFkaW5nJTIwYm9vayUyMGNvZmZlZXxlbnwxfHx8fDE3Njc4ODMwODJ8MA&ixlib=rb-4.1.0&q=80&w=1080",
      progress: 100,
      totalPages: 320,
      currentPage: 320,
      status: "completed",
      pdfUrl: "/sample.pdf",
      genre: "Self-Help",
      pagesPerMinute: 1.5,
      totalTimeSpent: 320,
      dateAdded: "2025-12-28",
      dateStarted: "2025-12-29",
      dateCompleted: "2026-01-05",
    },
    {
      id: "3",
      title: "The Silent Patient",
      author: "Alex Michaelides",
      cover: "https://images.unsplash.com/photo-1582087152266-3fbaf83bc952?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxsaWJyYXJ5JTIwYm9va3NoZWxmfGVufDF8fHx8MTc2Nzk3ODQ1N3ww&ixlib=rb-4.1.0&q=80&w=1080",
      progress: 0,
      totalPages: 336,
      currentPage: 0,
      status: "want-to-read",
      pdfUrl: "/sample.pdf",
      genre: "Thriller",
      dateAdded: "2026-01-07",
    },
    {
      id: "4",
      title: "Educated",
      author: "Tara Westover",
      cover: "https://images.unsplash.com/photo-1534289855405-ab820a118fc1?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHx2aW50YWdlJTIwYm9va3xlbnwxfHx8fDE3Njc4OTc5NjF8MA&ixlib=rb-4.1.0&q=80&w=1080",
      progress: 45,
      totalPages: 352,
      currentPage: 158,
      status: "reading",
      pdfUrl: "/sample.pdf",
      genre: "Biography",
      pagesPerMinute: 2.1,
      totalTimeSpent: 150,
      dateAdded: "2026-01-01",
      dateStarted: "2026-01-02",
    },
    {
      id: "5",
      title: "1984",
      author: "George Orwell",
      cover: "https://images.unsplash.com/photo-1636262454420-364d3a97e3e7?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxib29rJTIwY292ZXIlMjBub3ZlbHxlbnwxfHx8fDE3Njc5NTMxOTR8MA&ixlib=rb-4.1.0&q=80&w=1080",
      progress: 100,
      totalPages: 328,
      currentPage: 328,
      status: "completed",
      pdfUrl: "/sample.pdf",
      genre: "Dystopian",
      pagesPerMinute: 1.6,
      totalTimeSpent: 310,
      dateAdded: "2025-12-20",
      dateStarted: "2025-12-21",
      dateCompleted: "2026-01-01",
    },
    {
      id: "6",
      title: "The Alchemist",
      author: "Paulo Coelho",
      cover: "https://images.unsplash.com/photo-1707142979946-a745d1d0092c?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxyZWFkaW5nJTIwYm9vayUyMGNvZmZlZXxlbnwxfHx8fDE3Njc4ODMwODJ8MA&ixlib=rb-4.1.0&q=80&w=1080",
      progress: 0,
      totalPages: 208,
      currentPage: 0,
      status: "want-to-read",
      genre: "Fiction",
      dateAdded: "2026-01-08",
    },
  ]);

  const handleOpenBook = (book: BookData) => {
    setSelectedBook(book);
    setShowBookDetail(true);
    
    // Butler notification
    if (book.status === "reading") {
      toast.info("📖 The Butler has prepared your reading session, Sir.", {
        description: `${book.title} awaits your attention.`,
      });
    }
  };

  const handleOpenPdf = () => {
    setShowBookDetail(false);
    setShowPdfReader(true);
    
    toast.success("📄 PDF opened successfully", {
      description: "The Butler has optimized the reading experience.",
    });
  };

  const handleStartSession = (book: BookData) => {
    setSelectedBook(book);
    setShowBookDetail(false);
    setShowReadingSession(true);
    
    toast.success("⏱️ Reading session started!", {
      description: "The Butler is now tracking your progress.",
    });
  };

  const handlePageChange = (page: number) => {
    if (selectedBook) {
      const progress = Math.round((page / selectedBook.totalPages) * 100);
      const updatedBook = { ...selectedBook, currentPage: page, progress };
      setSelectedBook(updatedBook);
      
      // Update in books array
      setBooks(books.map(b => b.id === updatedBook.id ? updatedBook : b));
    }
  };

  const handleSessionComplete = (page: number, duration: number, notes: string[]) => {
    if (selectedBook) {
      const pagesRead = page - selectedBook.currentPage;
      const pagesPerMinute = duration > 0 ? pagesRead / duration : 0;
      const progress = Math.round((page / selectedBook.totalPages) * 100);
      
      const updatedBook = {
        ...selectedBook,
        currentPage: page,
        progress,
        pagesPerMinute,
        totalTimeSpent: (selectedBook.totalTimeSpent || 0) + duration,
      };
      
      setSelectedBook(updatedBook);
      setBooks(books.map(b => b.id === updatedBook.id ? updatedBook : b));
      
      // Butler notifications based on achievement
      if (pagesRead > 0) {
        if (progress === 100) {
          toast.success("🎉 Magnificent achievement!", {
            description: `You've completed "${selectedBook.title}"! The Butler is most impressed, Sir.`,
            duration: 5000,
          });
        } else if (progress >= 50 && selectedBook.progress < 50) {
          toast.success("🎯 Halfway milestone!", {
            description: `You've reached the midpoint of "${selectedBook.title}". Excellent progress!`,
            duration: 4000,
          });
        } else {
          toast.success(`📚 Session complete!`, {
            description: `${pagesRead} pages read in ${duration} minutes. Reading speed: ${pagesPerMinute.toFixed(1)} pages/min.`,
            duration: 4000,
          });
        }
        
        // Additional insights
        if (pagesPerMinute > 2) {
          setTimeout(() => {
            toast.info("⚡ Exceptional reading velocity!", {
              description: "Your focus today is remarkable, Sir.",
            });
          }, 2000);
        }
      }
    }
  };

  const booksReading = books.filter(b => b.status === "reading");
  const booksCompleted = books.filter(b => b.status === "completed");
  const booksWantToRead = books.filter(b => b.status === "want-to-read");

  const filteredBooks = books.filter(book => 
    book.title.toLowerCase().includes(searchQuery.toLowerCase()) ||
    book.author.toLowerCase().includes(searchQuery.toLowerCase())
  );

  const totalPagesRead = books
    .filter(b => b.status === "completed")
    .reduce((sum, b) => sum + b.totalPages, 0);

  // PDF Reader View
  if (showPdfReader && selectedBook) {
    return (
      <PdfReader
        bookTitle={selectedBook.title}
        author={selectedBook.author}
        currentPage={selectedBook.currentPage}
        totalPages={selectedBook.totalPages}
        progress={selectedBook.progress}
        onClose={() => setShowPdfReader(false)}
        onPageChange={handlePageChange}
      />
    );
  }

  // Book Detail View
  if (showBookDetail && selectedBook) {
    return (
      <BookDetail
        book={selectedBook}
        onClose={() => setShowBookDetail(false)}
        onOpenPdf={handleOpenPdf}
        onStartSession={handleStartSession}
      />
    );
  }

  // Reading Session View
  if (showReadingSession && selectedBook) {
    return (
      <ReadingSession
        book={selectedBook}
        onClose={() => setShowReadingSession(false)}
        onComplete={handleSessionComplete}
      />
    );
  }

  // Share Card Generator
  if (showShareCard && selectedBook) {
    return (
      <ShareCardGenerator
        book={selectedBook}
        onClose={() => setShowShareCard(false)}
      />
    );
  }

  return (
    <div className="min-h-screen bg-gray-50 flex items-center justify-center p-4">
      {/* Mobile Container */}
      <div className="w-full max-w-md h-[844px] bg-white rounded-3xl shadow-2xl overflow-hidden flex flex-col">
        {/* Top Bar */}
        <div className="bg-white border-b border-gray-200 px-4 pt-4 pb-3">
          <div className="flex items-center justify-between mb-3">
            <div className="flex items-center gap-2">
              <div className="p-1.5 bg-gradient-to-br from-purple-500 to-indigo-600 rounded-lg">
                <Sparkles className="size-5 text-white" />
              </div>
              <h1 className="text-2xl font-bold text-gray-900">The Butler</h1>
            </div>
            <Button variant="ghost" size="icon">
              <Plus className="size-5" />
            </Button>
          </div>
          
          {currentView !== "stats" && (
            <div className="relative">
              <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 size-4 text-gray-400" />
              <Input
                type="text"
                placeholder="Search books..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                className="pl-10 bg-gray-50 border-gray-200"
              />
            </div>
          )}
        </div>

        {/* Main Content */}
        <div className="flex-1 overflow-auto">
          {currentView === "home" && (
            <div className="p-4 space-y-6">
              {/* Currently Reading Section */}
              <div>
                <h2 className="text-lg font-semibold text-gray-900 mb-3">Continue Reading</h2>
                <div className="space-y-3">
                  {booksReading.length > 0 ? (
                    booksReading.map((book) => (
                      <BookCard
                        key={book.id}
                        book={book}
                        onOpen={() => handleOpenBook(book)}
                        variant="compact"
                      />
                    ))
                  ) : (
                    <div className="text-center py-8 text-gray-500">
                      <p className="text-sm">No books in progress</p>
                    </div>
                  )}
                </div>
              </div>

              {/* Recently Completed */}
              {booksCompleted.length > 0 && (
                <div>
                  <h2 className="text-lg font-semibold text-gray-900 mb-3">Recently Completed</h2>
                  <div className="space-y-3">
                    {booksCompleted.slice(0, 2).map((book) => (
                      <BookCard
                        key={book.id}
                        book={book}
                        onOpen={() => handleOpenBook(book)}
                        variant="compact"
                      />
                    ))}
                  </div>
                </div>
              )}

              {/* Want to Read */}
              {booksWantToRead.length > 0 && (
                <div>
                  <h2 className="text-lg font-semibold text-gray-900 mb-3">Want to Read</h2>
                  <div className="space-y-3">
                    {booksWantToRead.slice(0, 2).map((book) => (
                      <BookCard
                        key={book.id}
                        book={book}
                        onOpen={() => handleOpenBook(book)}
                        variant="compact"
                      />
                    ))}
                  </div>
                </div>
              )}
            </div>
          )}

          {currentView === "library" && (
            <Tabs defaultValue="all" className="p-4">
              <TabsList className="grid w-full grid-cols-4 mb-4">
                <TabsTrigger value="all">All</TabsTrigger>
                <TabsTrigger value="reading">Reading</TabsTrigger>
                <TabsTrigger value="completed">Done</TabsTrigger>
                <TabsTrigger value="want">Wishlist</TabsTrigger>
              </TabsList>

              <TabsContent value="all" className="space-y-4 mt-0">
                {filteredBooks.map((book) => (
                  <BookCard
                    key={book.id}
                    book={book}
                    onOpen={() => handleOpenBook(book)}
                    variant="compact"
                  />
                ))}
              </TabsContent>

              <TabsContent value="reading" className="space-y-4 mt-0">
                {filteredBooks.filter(b => b.status === "reading").map((book) => (
                  <BookCard
                    key={book.id}
                    book={book}
                    onOpen={() => handleOpenBook(book)}
                    variant="compact"
                  />
                ))}
              </TabsContent>

              <TabsContent value="completed" className="space-y-4 mt-0">
                {filteredBooks.filter(b => b.status === "completed").map((book) => (
                  <BookCard
                    key={book.id}
                    book={book}
                    onOpen={() => handleOpenBook(book)}
                    variant="compact"
                  />
                ))}
              </TabsContent>

              <TabsContent value="want" className="space-y-4 mt-0">
                {filteredBooks.filter(b => b.status === "want-to-read").map((book) => (
                  <BookCard
                    key={book.id}
                    book={book}
                    onOpen={() => handleOpenBook(book)}
                    variant="compact"
                  />
                ))}
              </TabsContent>
            </Tabs>
          )}

          {currentView === "stats" && (
            <StatsView
              totalBooks={books.length}
              booksReading={booksReading.length}
              booksCompleted={booksCompleted.length}
              booksWantToRead={booksWantToRead.length}
              totalPagesRead={totalPagesRead}
              currentStreak={9}
            />
          )}
        </div>

        {/* Bottom Navigation */}
        <div className="bg-white border-t border-gray-200 px-4 py-3 safe-area-inset-bottom">
          <div className="flex items-center justify-around">
            <Button
              variant={currentView === "home" ? "default" : "ghost"}
              size="sm"
              onClick={() => setCurrentView("home")}
              className="flex-col h-auto py-2 px-6"
            >
              <Home className="size-5 mb-1" />
              <span className="text-xs">Home</span>
            </Button>
            <Button
              variant={currentView === "library" ? "default" : "ghost"}
              size="sm"
              onClick={() => setCurrentView("library")}
              className="flex-col h-auto py-2 px-6"
            >
              <Library className="size-5 mb-1" />
              <span className="text-xs">Library</span>
            </Button>
            <Button
              variant={currentView === "stats" ? "default" : "ghost"}
              size="sm"
              onClick={() => setCurrentView("stats")}
              className="flex-col h-auto py-2 px-6"
            >
              <BarChart3 className="size-5 mb-1" />
              <span className="text-xs">Stats</span>
            </Button>
          </div>
        </div>
      </div>
      
      {/* Toast Notifications */}
      <Toaster position="top-center" richColors />
    </div>
  );
}