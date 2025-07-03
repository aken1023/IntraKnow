declare module 'react-input-otp' {
  import * as React from 'react'

  export interface OTPInputProps {
    value?: string
    onChange?: (value: string) => void
    numInputs?: number
    renderInput?: (props: any) => React.ReactNode
    renderSeparator?: (index: number) => React.ReactNode
    containerClassName?: string
    className?: string
    disabled?: boolean
    autoFocus?: boolean
    secure?: boolean
    placeholder?: string
  }

  export interface OTPInputContextType {
    slots: Array<{
      char: string
      hasFakeCaret: boolean
      isActive: boolean
    }>
  }

  export const OTPInput: React.ForwardRefExoticComponent<
    OTPInputProps & React.RefAttributes<HTMLDivElement>
  >

  export const OTPInputContext: React.Context<OTPInputContextType>
} 