import React from "react";
import { cn } from "@/lib/utils";

interface ResponsiveContainerProps extends React.HTMLAttributes<HTMLDivElement> {
  maxWidth?: "sm" | "md" | "lg" | "xl" | "2xl" | "full";
  padding?: boolean;
  centered?: boolean;
  className?: string;
}

/**
 * 響應式容器元件
 * 用於建立統一的 RWD 容器，可控制最大寬度、內邊距及對齊方式
 */
export function ResponsiveContainer({
  children,
  maxWidth = "xl",
  padding = true,
  centered = true,
  className,
  ...props
}: ResponsiveContainerProps) {
  return (
    <div
      className={cn(
        {
          "px-4 sm:px-6 md:px-8": padding,
          "mx-auto": centered,
          "max-w-screen-sm": maxWidth === "sm",
          "max-w-screen-md": maxWidth === "md",
          "max-w-screen-lg": maxWidth === "lg",
          "max-w-screen-xl": maxWidth === "xl",
          "max-w-screen-2xl": maxWidth === "2xl",
          "max-w-full": maxWidth === "full",
        },
        className
      )}
      {...props}
    >
      {children}
    </div>
  );
} 