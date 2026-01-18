import { Book, Library, Plus, Search } from "lucide-react";
import { Card } from "./ui/card";
import { Input } from "./ui/input";
import { Button } from "./ui/button";
import { Progress } from "./ui/progress";
import { Badge } from "./ui/badge";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "./ui/tabs";

interface BookItem {
  id: string;
  title: string;
  author: string;
  status: "reading" | "want-to-read" | "finished";
  progress: number;
  totalPages: number;
  coverColor: string;
  pdfFile?: File;
}

interface BookListProps {
  books: BookItem[];
  searchQuery: string;
  activeTab: string;
  onSearchChange: (query: string) => void;
  onTabChange: (tab: string) => void;
  onBookClick: (book: BookItem) => void;
  onAddBook: () => void;
}

export function BookList({
  books,
  searchQuery,
  activeTab,
  onSearchChange,
  onTabChange,
  onBookClick,
  onAddBook,
}: BookListProps) {
  const filteredBooks = books.filter((book) => {
    const matchesSearch =
      book.title.toLowerCase().includes(searchQuery.toLowerCase()) ||
      book.author.toLowerCase().includes(searchQuery.toLowerCase());
    const matchesTab =
      activeTab === "all" || book.status === activeTab;
    return matchesSearch && matchesTab;
  });

  const getStatusBadge = (status: BookItem["status"]) => {
    const statusConfig = {
      reading: { label: "Reading", variant: "default" as const },
      "want-to-read": { label: "Want to Read", variant: "secondary" as const },
      finished: { label: "Finished", variant: "outline" as const },
    };
    return statusConfig[status];
  };

  return (
    <div className="flex flex-col h-full bg-background">
      {/* Header */}
      <div className="p-4 border-b bg-card">
        <div className="flex items-center gap-2 mb-4">
          <Library className="size-6 text-primary" />
          <h1 className="text-xl">My Library</h1>
        </div>

        {/* Search */}
        <div className="relative mb-4">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 size-4 text-muted-foreground" />
          <Input
            type="search"
            placeholder="Search books..."
            value={searchQuery}
            onChange={(e) => onSearchChange(e.target.value)}
            className="pl-10"
          />
        </div>

        {/* Add Book Button */}
        <Button onClick={onAddBook} className="w-full">
          <Plus className="size-4 mr-2" />
          Add Book
        </Button>
      </div>

      {/* Tabs */}
      <Tabs value={activeTab} onValueChange={onTabChange} className="flex-1 flex flex-col">
        <TabsList className="w-full grid grid-cols-4 rounded-none border-b">
          <TabsTrigger value="all">All</TabsTrigger>
          <TabsTrigger value="reading">Reading</TabsTrigger>
          <TabsTrigger value="want-to-read">Want</TabsTrigger>
          <TabsTrigger value="finished">Done</TabsTrigger>
        </TabsList>

        <TabsContent value={activeTab} className="flex-1 overflow-auto p-4 mt-0">
          {filteredBooks.length === 0 ? (
            <div className="flex flex-col items-center justify-center h-full text-center text-muted-foreground">
              <Book className="size-12 mb-2 opacity-50" />
              <p>No books found</p>
              <p className="text-sm">Add your first book to get started</p>
            </div>
          ) : (
            <div className="grid gap-3">
              {filteredBooks.map((book) => {
                const statusBadge = getStatusBadge(book.status);
                const progressPercent = (book.progress / book.totalPages) * 100;

                return (
                  <Card
                    key={book.id}
                    className="p-4 cursor-pointer hover:bg-accent transition-colors"
                    onClick={() => onBookClick(book)}
                  >
                    <div className="flex gap-3">
                      {/* Book Cover */}
                      <div
                        className="w-16 h-24 rounded flex-shrink-0 flex items-center justify-center"
                        style={{ backgroundColor: book.coverColor }}
                      >
                        <Book className="size-8 text-white opacity-70" />
                      </div>

                      {/* Book Info */}
                      <div className="flex-1 min-w-0">
                        <h3 className="truncate mb-1">{book.title}</h3>
                        <p className="text-sm text-muted-foreground truncate mb-2">
                          {book.author}
                        </p>
                        <Badge variant={statusBadge.variant} className="mb-2">
                          {statusBadge.label}
                        </Badge>
                        {book.status === "reading" && (
                          <div className="space-y-1">
                            <div className="flex justify-between text-xs text-muted-foreground">
                              <span>
                                Page {book.progress} of {book.totalPages}
                              </span>
                              <span>{Math.round(progressPercent)}%</span>
                            </div>
                            <Progress value={progressPercent} className="h-1" />
                          </div>
                        )}
                      </div>
                    </div>
                  </Card>
                );
              })}
            </div>
          )}
        </TabsContent>
      </Tabs>
    </div>
  );
}
