using System;
using System.Collections.Generic;

namespace Roblox.Moderation
{
    public class UserModerationNote
    {
        public long ID { get; set; }
        public int UserID { get; set; }
        public int ModeratorID { get; set; }
        public string Text { get; set; }
        public DateTime Created { get; set; }

        public void Save() { }

        public static IEnumerable<UserModerationNote> GetUserModerationNotesByUserIDPaged(
            int startRowIndex, int maximumRows, int userId)
            => new List<UserModerationNote>();
    }

    public class PunishmentType
    {
        public byte ID { get; set; }
        public string Value { get; set; }
        public int? DurationInDays { get; set; }

        public static PunishmentType Get(byte id) => new PunishmentType { ID = id };
        public static IEnumerable<PunishmentType> AllPunishmentTypes => new List<PunishmentType>();

        public static PunishmentType DeleteAccount => new PunishmentType { Value = "DeleteAccount" };
        public static PunishmentType PoisonMachine => new PunishmentType { Value = "PoisonMachine" };
        public static PunishmentType Remind       => new PunishmentType { Value = "Remind" };
        public static PunishmentType Warn         => new PunishmentType { Value = "Warn" };
        public static PunishmentType None         => new PunishmentType { Value = "None" };
    }

    public class Punishment
    {
        public long ID { get; set; }
        public PunishmentType PunishmentType { get; set; }
        public long ModeratorID { get; set; }
        public string Comment { get; set; }
        public string ModeratorMessage { get; set; }
        public DateTime Created { get; set; }
        public DateTime? Expiration { get; set; }

        public static IEnumerable<Punishment> GetPunishmentsByUserIDPaged(
            int startRowIndex, int maximumRows, int userId)
            => new List<Punishment>();

        public static long GetTotalNumberOfPunishmentsByUserID(long userId) => 0;
        public static long GetTotalNumberOfActivePunishmentsByUserID(long userId) => 0;

        public static IEnumerable<Punishment> GetActivePunishmentsByUserIDPaged(
            int startRowIndex, int maximumRows, int userId)
            => new List<Punishment>();

        public static Punishment CreateNew(
            int userId, byte punishmentTypeId, int? appealId,
            int moderatorId, string comment, string message)
            => new Punishment();
    }
}
