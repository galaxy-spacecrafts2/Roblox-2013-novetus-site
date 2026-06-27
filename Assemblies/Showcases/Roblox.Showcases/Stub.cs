using System;
using System.Collections.Generic;

namespace Roblox.Showcases.Entities
{
    public interface IAsset
    {
        long Id { get; }
        string Name { get; }
    }

    public enum ShowcaseType { Places = 0 }
    public enum CreatorType   { User = 0, Group = 1 }

    public class Showcase
    {
        public long ID { get; set; }

        public static Showcase GetOrCreate(
            ShowcaseType type, CreatorType creatorType, long creatorId)
            => new Showcase();
    }

    public class ShowcaseItem
    {
        public IAsset Asset { get; set; }

        public static IEnumerable<ShowcaseItem> GetShowcaseItemsByShowcaseIDPaged(
            int startRowIndex, int maximumRows, long showcaseId)
            => new List<ShowcaseItem>();
    }
}
