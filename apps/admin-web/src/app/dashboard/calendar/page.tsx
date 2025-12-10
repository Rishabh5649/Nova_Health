
'use client';
// Actually, keep it server component but lazy import the client part? 
// No, React.lazy works best in client components or with dynamic imports in server components.
// Let's stick to the Server Component pattern but use 'next/dynamic'.

import dynamic from 'next/dynamic';
import { Suspense } from 'react';

// Lazy load the client component with no SSR to strictly avoid build-time execution of hooks
const CalendarContent = dynamic(() => import('./CalendarContent'), {
    ssr: false,
    loading: () => <div>Loading calendar...</div>
});

// Force dynamic rendering
export const dynamicParams = true; // true | false,
export const revalidate = 0;

export default function CalendarPage() {
    return (
        <CalendarContent />
    );
}
