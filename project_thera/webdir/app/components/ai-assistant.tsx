import { useState } from "react";
import { Send, Bot, User, Sparkles } from "lucide-react";
import { Button } from "./ui/button";
import { Input } from "./ui/input";
import { Card } from "./ui/card";
import { ScrollArea } from "./ui/scroll-area";

interface Message {
  id: string;
  role: "user" | "assistant";
  content: string;
  timestamp: Date;
}

interface AIAssistantProps {
  bookTitle?: string;
}

export function AIAssistant({ bookTitle }: AIAssistantProps) {
  const [messages, setMessages] = useState<Message[]>([
    {
      id: "1",
      role: "assistant",
      content: "Good day! I am your Butler, at your service. How may I assist with your reading journey today?",
      timestamp: new Date(),
    },
  ]);
  const [input, setInput] = useState("");

  const quickActions = [
    "What was that quote about stoicism?",
    "Summarize my notes",
    "When will I finish this book?",
    "Show my reading stats",
  ];

  const handleSend = () => {
    if (!input.trim()) return;

    const userMessage: Message = {
      id: Date.now().toString(),
      role: "user",
      content: input,
      timestamp: new Date(),
    };

    setMessages([...messages, userMessage]);
    setInput("");

    // Simulate AI response
    setTimeout(() => {
      const response = generateButlerResponse(input, bookTitle);
      const assistantMessage: Message = {
        id: (Date.now() + 1).toString(),
        role: "assistant",
        content: response,
        timestamp: new Date(),
      };
      setMessages((prev) => [...prev, assistantMessage]);
    }, 1000);
  };

  const handleQuickAction = (action: string) => {
    setInput(action);
  };

  return (
    <div className="flex flex-col h-full">
      {/* Header */}
      <div className="p-4 border-b border-gray-200 bg-gradient-to-r from-indigo-50 to-purple-50">
        <div className="flex items-center gap-2">
          <div className="p-2 bg-indigo-600 rounded-full">
            <Bot className="size-5 text-white" />
          </div>
          <div>
            <h3 className="font-semibold text-gray-900">The Butler</h3>
            <p className="text-xs text-gray-600">Your Intelligent Librarian</p>
          </div>
        </div>
      </div>

      {/* Messages */}
      <ScrollArea className="flex-1 p-4">
        <div className="space-y-4">
          {messages.map((message) => (
            <div
              key={message.id}
              className={`flex gap-2 ${
                message.role === "user" ? "justify-end" : "justify-start"
              }`}
            >
              {message.role === "assistant" && (
                <div className="p-2 bg-indigo-100 rounded-full h-8 w-8 flex items-center justify-center flex-shrink-0">
                  <Bot className="size-4 text-indigo-600" />
                </div>
              )}
              <div
                className={`max-w-[80%] rounded-lg p-3 ${
                  message.role === "user"
                    ? "bg-indigo-600 text-white"
                    : "bg-gray-100 text-gray-900"
                }`}
              >
                <p className="text-sm">{message.content}</p>
                <p className="text-xs mt-1 opacity-70">
                  {message.timestamp.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                </p>
              </div>
              {message.role === "user" && (
                <div className="p-2 bg-indigo-600 rounded-full h-8 w-8 flex items-center justify-center flex-shrink-0">
                  <User className="size-4 text-white" />
                </div>
              )}
            </div>
          ))}
        </div>
      </ScrollArea>

      {/* Quick Actions */}
      <div className="p-3 border-t border-gray-200 bg-gray-50">
        <div className="flex gap-2 overflow-x-auto pb-2">
          {quickActions.map((action) => (
            <Button
              key={action}
              variant="outline"
              size="sm"
              onClick={() => handleQuickAction(action)}
              className="text-xs whitespace-nowrap"
            >
              <Sparkles className="size-3 mr-1" />
              {action}
            </Button>
          ))}
        </div>
      </div>

      {/* Input */}
      <div className="p-4 border-t border-gray-200">
        <div className="flex gap-2">
          <Input
            value={input}
            onChange={(e) => setInput(e.target.value)}
            onKeyPress={(e) => e.key === "Enter" && handleSend()}
            placeholder="Ask the Butler anything..."
            className="flex-1"
          />
          <Button onClick={handleSend} disabled={!input.trim()}>
            <Send className="size-4" />
          </Button>
        </div>
      </div>
    </div>
  );
}

function generateButlerResponse(input: string, bookTitle?: string): string {
  const lowerInput = input.toLowerCase();

  if (lowerInput.includes("quote") || lowerInput.includes("stoicism")) {
    return "Ah yes, from your notes on Chapter 2: 'The obstacle is the way.' You highlighted this passage about turning challenges into opportunities. Shall I retrieve the full context?";
  }

  if (lowerInput.includes("summarize") || lowerInput.includes("notes")) {
    return "Certainly. You've made 12 notes across 8 chapters. The key themes you've highlighted are: resilience, personal growth, and mindfulness. Would you like me to compile these into a summary document?";
  }

  if (lowerInput.includes("finish") || lowerInput.includes("when")) {
    return `At your current pace of 32 pages per day, you will complete ${bookTitle || "this book"} in approximately 8 days, on January 17th. Shall I set a reminder to check in?`;
  }

  if (lowerInput.includes("stats") || lowerInput.includes("reading")) {
    return "Your reading statistics are quite impressive! This week you've read for 4.2 hours across 3 sessions, averaging 28 pages per day. Your most productive reading time is between 8-10 PM.";
  }

  return "I understand you're inquiring about your reading journey. I can help you find notes, predict completion dates, generate summaries, or analyze your reading patterns. What would you like to explore?";
}
