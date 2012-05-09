\name{encodeOverlaps-methods}
\alias{encodeOverlaps-methods}

\alias{flipQuery}

\alias{encodeOverlaps,GRangesList,GRangesList,missing-method}

\alias{selectEncodingWithCompatibleStrand}

\alias{isCompatibleWithSplicing}
\alias{isCompatibleWithSplicing,character-method}
\alias{isCompatibleWithSplicing,factor-method}
\alias{isCompatibleWithSplicing,OverlapEncodings-method}

\alias{isCompatibleWithSkippedExons}
\alias{isCompatibleWithSkippedExons,character-method}
\alias{isCompatibleWithSkippedExons,factor-method}
\alias{isCompatibleWithSkippedExons,OverlapEncodings-method}

\alias{extractSkippedExonRanks}
\alias{extractSkippedExonRanks,character-method}
\alias{extractSkippedExonRanks,factor-method}
\alias{extractSkippedExonRanks,OverlapEncodings-method}

\title{encodeOverlaps methods and related utilities}

\description{
  \code{encodeOverlaps} methods and related utilities.

  WARNING: This man page is incomplete and was still a WORK IN PROGRESS
  at the time GenomicRanges 1.8 was released (as part of Bioconductor 2.10,
  released in April 2012). All the work on "overlap encodings" is now happening
  in the \emph{devel} version of the GenomicRanges package (GenomicRanges 1.9
  part of Bioconductor 2.11, at the time of this writing). To use "overlap
  encodings" and related tools, and to get an updated version of the
  "Overlap encodings" vignette, it is \emph{strongly} recommended that you use
  Bioconductor 2.11. In particular please make sure that you always use the
  \emph{latest} version of the GenomicRanges package (version 1.9.14 at the
  time of this writing, expect frequent updates).

  In other words, this man page is superseded by the man page found in
  GenomicRanges 1.9 (part of Bioconductor 2.11). It won't be updated.

  See \code{?useDevel} in the BiocInstaller package for how to use the devel
  version of Bioconductor (2.11 at the time of this writing).

  See \code{?biocLite} in the BiocInstaller package for how to update all
  the installed packages.
}

\usage{
flipQuery(x, i)

\S4method{encodeOverlaps}{GRangesList,GRangesList,missing}(query, subject, hits=NULL,
               flip.query.if.wrong.strand=FALSE)

selectEncodingWithCompatibleStrand(x, y,
                                   query.strand, subject.strand, hits=NULL)
isCompatibleWithSplicing(x)
isCompatibleWithSkippedExons(x, max.skipped.exons=NA)
extractSkippedExonRanks(x)
}

\arguments{
  \item{x}{
    For \code{flipQuery}: A \link{GRangesList} object.

    For \code{selectEncodingWithCompatibleStrand}:
    An \link[IRanges]{OverlapEncodings} object.

    For \code{isCompatibleWithSplicing}, \code{isCompatibleWithSkippedExons},
    and \code{extractSkippedExonRanks}:
    An \link[IRanges]{OverlapEncodings} object, a factor or a character
    vector.
  }
  \item{i}{
    Subscript specifying the elements in \code{x} to flip. If missing, all
    the elements are flipped.
  }
  \item{query, subject}{
    \link{GRangesList}, \link[IRanges]{RangesList} or \link[IRanges]{Ranges}
    objects.
  }
  \item{hits}{
    A \link[IRanges]{Hits} object.
    See \code{?`\link[IRanges]{encodeOverlaps,ANY,ANY,Hits-method}`} for
    a description of how a supplied \link[IRanges]{Hits} object is handled.
  }
  \item{flip.query.if.wrong.strand}{
    See the "Overlap encodings" vignette in the GenomicRanges package.
  }
  \item{y}{
    An \link[IRanges]{OverlapEncodings} object.
  }
  \item{query.strand, subject.strand}{
    Vector-like objects containing the strand of the query and subject,
    respectively.
  }
  \item{max.skipped.exons}{
    Not supported yet. If \code{NA} (the default), the number of skipped
    exons must be 1 or more (there is no max).
  }
}

\details{
  In the context of an RNA-seq experiment, encoding the overlaps
  between 2 \link{GRangesList} objects, one containing the reads (the query),
  and one containing the transcripts (the subject), can be used for
  detecting hits between reads and transcripts that are \emph{compatible}
  with the splicing of the transcript.

  The topic of working with overlap encodings is covered in details
  in the "Overlap encodings" vignette in the GenomicRanges package.
}

\author{
  H. Pages
}

\seealso{
  \itemize{
    \item The "Overlap encodings" vignette in the GenomicRanges package.
    \item \code{\link[IRanges]{findOverlaps}}.
    \item \link[IRanges]{OverlapEncodings-class}.
    \item \link{GRangesList-class}.
  }
}

\examples{
## See the "Overlap encodings" vignette in the GenomicRanges package for
## some examples.
}

\keyword{methods}
\keyword{utilities}
