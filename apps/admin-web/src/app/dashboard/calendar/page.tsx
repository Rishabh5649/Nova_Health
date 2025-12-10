import dynamicLoader from 'next/dynamic';
import { Suspense } from 'react';

// Lazy load the client component with no SSR to strictly avoid build-time execution of hooks
const CalendarContent = dynamicLoader(() => import('./CalendarContent'), {
    ssr: false,
    loading: () => <div>Loading calendar...</div>
});

// Force dynamic rendering
export const dynamic = 'force-dynamic';
export const revalidate = 0;

export default function CalendarPage() {
    return (
        <Suspense fallback={<div>Loading calendar...</div>}>
            <CalendarContent />
        </Suspense>
    );
}
