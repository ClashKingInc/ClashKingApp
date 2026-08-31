import {
  AnnouncementOpeningController,
  isOpeningAnnouncementEligible,
} from './announcement-opening-controller';
import { AppAnnouncement } from './app-announcement';

const story = new AppAnnouncement(
  'story',
  'Story',
  'Details',
  '1',
  null,
  null,
  null,
  'https://cdn.example.com/story.html',
  null,
);

test('automatic opening requires native, enabled, current, story, and opt-in state', async () => {
  expect(
    isOpeningAnnouncementEligible({
      platform: 'web',
      featureEnabled: true,
      routeCurrent: true,
      announcement: story,
    }),
  ).toBe(false);

  const markDismissed = jest.fn(async () => undefined);
  const presentStory = jest.fn(async () => true);
  const controller = new AnnouncementOpeningController({
    platform: 'ios',
    featureEnabled: () => true,
    routeCurrent: () => true,
    openingAnnouncement: Promise.resolve(story),
    shouldPresent: async () => true,
    prepareStory: async () => 'file:///story.html',
    presentStory,
    markDismissed,
  });

  await expect(controller.tryPresent()).resolves.toBe(true);
  expect(presentStory).toHaveBeenCalledWith(story, 'file:///story.html');
  expect(markDismissed).toHaveBeenCalledWith(story);
});

test('does not dismiss when the route stops being current during preparation', async () => {
  let current = true;
  const markDismissed = jest.fn();
  const controller = new AnnouncementOpeningController({
    platform: 'android',
    featureEnabled: () => true,
    routeCurrent: () => current,
    openingAnnouncement: Promise.resolve(story),
    shouldPresent: async () => true,
    prepareStory: async () => {
      current = false;
      return 'file:///story.html';
    },
    presentStory: jest.fn(async () => true),
    markDismissed,
  });

  await expect(controller.tryPresent()).resolves.toBe(false);
  expect(markDismissed).not.toHaveBeenCalled();
});
