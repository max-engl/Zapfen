import { createContext, useContext } from 'react'

export const ToastContext = createContext(null)
export const LightboxContext = createContext(null)

export const useToast = () => useContext(ToastContext)
export const useLightbox = () => useContext(LightboxContext)
