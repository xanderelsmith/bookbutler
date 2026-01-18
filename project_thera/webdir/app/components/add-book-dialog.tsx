import { useState } from "react";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogFooter,
} from "./ui/dialog";
import { Input } from "./ui/input";
import { Label } from "./ui/label";
import { Button } from "./ui/button";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "./ui/select";
import { Upload } from "lucide-react";

interface AddBookDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  onAddBook: (book: {
    title: string;
    author: string;
    status: "reading" | "want-to-read" | "finished";
    totalPages: number;
    pdfFile?: File;
  }) => void;
}

export function AddBookDialog({ open, onOpenChange, onAddBook }: AddBookDialogProps) {
  const [title, setTitle] = useState("");
  const [author, setAuthor] = useState("");
  const [status, setStatus] = useState<"reading" | "want-to-read" | "finished">("want-to-read");
  const [totalPages, setTotalPages] = useState("");
  const [pdfFile, setPdfFile] = useState<File | null>(null);

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.files && e.target.files[0]) {
      setPdfFile(e.target.files[0]);
    }
  };

  const handleSubmit = () => {
    if (!title || !author || !totalPages) {
      return;
    }

    onAddBook({
      title,
      author,
      status,
      totalPages: parseInt(totalPages),
      pdfFile: pdfFile || undefined,
    });

    // Reset form
    setTitle("");
    setAuthor("");
    setStatus("want-to-read");
    setTotalPages("");
    setPdfFile(null);
    onOpenChange(false);
  };

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-w-md">
        <DialogHeader>
          <DialogTitle>Add New Book</DialogTitle>
        </DialogHeader>

        <div className="space-y-4 py-4">
          <div className="space-y-2">
            <Label htmlFor="title">Title *</Label>
            <Input
              id="title"
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              placeholder="Enter book title"
            />
          </div>

          <div className="space-y-2">
            <Label htmlFor="author">Author *</Label>
            <Input
              id="author"
              value={author}
              onChange={(e) => setAuthor(e.target.value)}
              placeholder="Enter author name"
            />
          </div>

          <div className="space-y-2">
            <Label htmlFor="status">Status</Label>
            <Select value={status} onValueChange={(value: any) => setStatus(value)}>
              <SelectTrigger id="status">
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="want-to-read">Want to Read</SelectItem>
                <SelectItem value="reading">Reading</SelectItem>
                <SelectItem value="finished">Finished</SelectItem>
              </SelectContent>
            </Select>
          </div>

          <div className="space-y-2">
            <Label htmlFor="pages">Total Pages *</Label>
            <Input
              id="pages"
              type="number"
              value={totalPages}
              onChange={(e) => setTotalPages(e.target.value)}
              placeholder="e.g., 350"
            />
          </div>

          <div className="space-y-2">
            <Label htmlFor="pdf">PDF File (Optional)</Label>
            <div className="flex items-center gap-2">
              <Input
                id="pdf"
                type="file"
                accept=".pdf"
                onChange={handleFileChange}
                className="flex-1"
              />
              {pdfFile && (
                <Button
                  variant="ghost"
                  size="icon"
                  onClick={() => setPdfFile(null)}
                >
                  <Upload className="size-4" />
                </Button>
              )}
            </div>
            {pdfFile && (
              <p className="text-sm text-muted-foreground">{pdfFile.name}</p>
            )}
          </div>
        </div>

        <DialogFooter>
          <Button variant="outline" onClick={() => onOpenChange(false)}>
            Cancel
          </Button>
          <Button onClick={handleSubmit} disabled={!title || !author || !totalPages}>
            Add Book
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
