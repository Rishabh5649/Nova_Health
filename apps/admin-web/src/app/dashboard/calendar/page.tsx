

import { Suspense } from 'react';
import CalendarContent from './CalendarContent';

export const dynamic = 'force-dynamic';

export default function CalendarPage() {
    return (
        <Suspense fallback={<div>Loading calendar...</div>}>
            <CalendarContent />
        </Suspense>
    );
}
