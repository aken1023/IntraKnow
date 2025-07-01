"use client";

import React, {
  createContext,
  useContext,
  useEffect,
  useState,
  ReactNode,
} from "react";

type Breakpoint = "xs" | "sm" | "md" | "lg" | "xl" | "2xl" | "3xl";

interface ViewportContextType {
  width: number;
  height: number;
  breakpoint: Breakpoint;
  isMobile: boolean;
  isTablet: boolean;
  isDesktop: boolean;
}

const ViewportContext = createContext<ViewportContextType | undefined>(
  undefined
);

const breakpoints = {
  xs: 390,
  sm: 640,
  md: 768,
  lg: 1024,
  xl: 1280,
  "2xl": 1536,
  "3xl": 1920,
};

interface ViewportProviderProps {
  children: ReactNode;
}

export const ViewportProvider = ({ children }: ViewportProviderProps) => {
  const [width, setWidth] = useState(0);
  const [height, setHeight] = useState(0);

  useEffect(() => {
    const handleResize = () => {
      setWidth(window.innerWidth);
      setHeight(window.innerHeight);
    };

    // 初始化
    handleResize();

    window.addEventListener("resize", handleResize);
    window.addEventListener("orientationchange", handleResize);

    return () => {
      window.removeEventListener("resize", handleResize);
      window.removeEventListener("orientationchange", handleResize);
    };
  }, []);

  // 確定當前斷點
  let currentBreakpoint: Breakpoint = "xs";
  if (width >= breakpoints["3xl"]) currentBreakpoint = "3xl";
  else if (width >= breakpoints["2xl"]) currentBreakpoint = "2xl";
  else if (width >= breakpoints.xl) currentBreakpoint = "xl";
  else if (width >= breakpoints.lg) currentBreakpoint = "lg";
  else if (width >= breakpoints.md) currentBreakpoint = "md";
  else if (width >= breakpoints.sm) currentBreakpoint = "sm";

  // 設備類型分類
  const isMobile = width < breakpoints.md;
  const isTablet = width >= breakpoints.md && width < breakpoints.lg;
  const isDesktop = width >= breakpoints.lg;

  return (
    <ViewportContext.Provider
      value={{
        width,
        height,
        breakpoint: currentBreakpoint,
        isMobile,
        isTablet,
        isDesktop,
      }}
    >
      {children}
    </ViewportContext.Provider>
  );
};

export const useViewport = () => {
  const context = useContext(ViewportContext);
  if (context === undefined) {
    throw new Error("useViewport must be used within a ViewportProvider");
  }
  return context;
};

// 輔助函數：根據不同斷點返回不同值
export function responsiveValue<T>(options: {
  xs?: T;
  sm?: T;
  md?: T;
  lg?: T;
  xl?: T;
  "2xl"?: T;
  "3xl"?: T;
  defaultValue: T;
}): T {
  const { breakpoint } = useViewport();
  
  // 按照斷點優先順序檢查
  const breakpointOrder: Breakpoint[] = ["xs", "sm", "md", "lg", "xl", "2xl", "3xl"];
  const index = breakpointOrder.indexOf(breakpoint);
  
  // 從當前斷點向下找到第一個有定義值的斷點
  for (let i = index; i >= 0; i--) {
    const bp = breakpointOrder[i];
    if (options[bp] !== undefined) {
      return options[bp] as T;
    }
  }
  
  return options.defaultValue;
} 