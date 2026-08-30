import { useAppRuntime } from '../../../core/app/runtime-context';
import { PostsScreen, type PostsScreenProps } from './posts-screen';

export function PostsRoot({ onBack, initialPostId }: Omit<PostsScreenProps, 'service'>) {
  const runtime = useAppRuntime();
  return (
    <PostsScreen initialPostId={initialPostId} onBack={onBack} service={runtime.announcements} />
  );
}
